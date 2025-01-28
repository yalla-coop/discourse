# frozen_string_literal: true

module Migrations::Uploader
  module Tasks
    class Uploader < Base
      MAX_FILE_SIZE = 1.gigabyte

      UploadMetadata = Struct.new(:original_filename, :origin_url, :description)

      def run!
        puts "", "Uploading uploads..."

        process_existing_uploads

        status_thread = start_status_thread
        consumer_threads = start_consumer_threads
        producer_thread = start_producer_thread

        producer_thread.join
        work_queue.close
        consumer_threads.each(&:join)
        status_queue.close
        status_thread.join
      end

      private

      def process_existing_uploads
        delete_missing_uploads if settings[:delete_missing_uploads]
        initialize_existing_ids_tracking_sets
        handle_surplus_uploads if surplus_upload_ids.any?

        @max_count = (@source_existing_ids - @output_existing_ids).size
        @source_existing_ids = nil

        puts "Found #{@output_existing_ids.size} existing uploads. #{@max_count} are missing."
      end

      def initialize_existing_ids_tracking_sets
        @output_existing_ids = load_existing_ids(uploads_db.db, Set.new)
        @source_existing_ids = load_existing_ids(intermediate_db.db, Set.new)
      end

      def load_existing_ids(db, set)
        db.query("SELECT id FROM uploads") { |row| set << row[:id] }

        set
      end

      def handle_surplus_uploads
        if settings[:delete_surplus_uploads]
          puts "Deleting #{surplus_upload_ids.size} uploads from output database..."

          surplus_upload_ids.each_slice(TRANSACTION_SIZE) do |ids|
            placeholders = (["?"] * ids.size).join(",")
            uploads_db.db.execute(<<~SQL, ids)
              DELETE FROM uploads
              WHERE id IN (#{placeholders})
            SQL
          end

          @output_existing_ids -= surplus_upload_ids
        else
          puts "Found #{surplus_upload_ids.size} surplus uploads in output database. " \
                 "Run with `delete_surplus_uploads: true` to delete them."
        end

        @surplus_upload_ids = nil
      end

      def surplus_upload_ids
        @surplus_upload_ids ||= @output_existing_ids - @source_existing_ids
      end

      def handle_status_update(params)
        @current_count += 1

        begin
          if params.delete(:skipped) == true
            @skipped_count += 1
          elsif (error_message = params.delete(:error)) || params[:upload].nil?
            @error_count += 1
            puts "", "Failed to create upload: #{params[:id]} (#{error_message})", ""
          end

          uploads_db.insert(<<~SQL, params)
            INSERT INTO uploads (id, upload, markdown, skip_reason)
            VALUES (:id, :upload, :markdown, :skip_reason)
          SQL
        rescue StandardError => e
          puts "", "Failed to insert upload: #{params[:id]} (#{e.message}))", ""
          @error_count += 1
        end
      end

      def enqueue_jobs
        intermediate_db
          .db
          .query("SELECT * FROM uploads ORDER BY id") do |row|
            work_queue << row if @output_existing_ids.exclude?(row[:id])
          end
      end

      def find_file_in_paths(row)
        relative_path = row[:relative_path] || ""

        settings[:root_paths].each do |root_path|
          path = File.join(root_path, relative_path, row[:filename])

          return path if File.exist?(path)

          settings[:path_replacements].each do |from, to|
            path = File.join(root_path, relative_path.sub(from, to), row[:filename])

            return path if File.exist?(path)
          end
        end

        nil
      end

      def handle_missing_file(row)
        status_queue << { id: row[:id], upload: nil, skipped: true, skip_reason: "file not found" }
      end

      def process_upload(row, _)
        metadata = build_metadata(row)
        data_file = nil
        path = nil

        if row[:data].present?
          data_file = Tempfile.new("discourse-upload", binmode: true)
          data_file.write(row[:data])
          data_file.rewind
          path = data_file.path
        elsif row[:url].present?
          path, metadata.original_filename = download_file(url: row[:url], id: row[:id])
          metadata.origin_url = row[:url]
          return if !path
        else
          path = find_file_in_paths(row)
          return handle_missing_file(row) if path.nil?
        end

        error_message = nil
        result =
          with_retries do
            upload =
              copy_to_tempfile(path) do |file|
                begin
                  UploadCreator.new(
                    file,
                    metadata.original_filename,
                    type: row[:type],
                    origin: metadata.origin_url,
                  ).create_for(Discourse::SYSTEM_USER_ID)
                rescue StandardError => e
                  error_message = e.message
                  nil
                end
              end

            if (upload_okay = upload.present? && upload.persisted? && upload.errors.blank?)
              upload_path = add_multisite_prefix(discourse_store.get_path_for_upload(upload))

              unless file_exists?(upload_path)
                upload.destroy
                upload = nil
                upload_okay = false
              end
            end

            if upload_okay
              {
                id: row[:id],
                upload: upload.attributes.to_json,
                markdown:
                  UploadMarkdown.new(upload).to_markdown(display_name: metadata.description),
                skip_reason: nil,
              }
            else
              error_message =
                upload&.errors&.full_messages&.join(", ") || error_message || "unknown error"
              nil
            end
          end

        if result.nil?
          status_queue << {
            id: row[:id],
            upload: nil,
            markdown: nil,
            error: "too many retries: #{error_message}",
            skip_reason: "too many retries",
          }
        else
          status_queue << result
        end
      rescue StandardError => e
        status_queue << {
          id: row[:id],
          upload: nil,
          markdown: nil,
          error: e.message,
          skip_reason: "error",
        }
      ensure
        data_file&.close!
      end

      def build_metadata(row)
        UploadMetadata.new(
          original_filename: row[:display_filename] || row[:filename],
          description: row[:description].presence,
        )
      end

      def delete_missing_uploads
        puts "Deleting missing uploads from uploads database..."

        uploads_db.db.execute(<<~SQL)
          DELETE FROM uploads
          WHERE upload IS NULL
        SQL
      end

      def download_file(url:, id:, retry_count: 0)
        path = download_cache_path(id)
        original_filename = nil

        if File.exist?(path) && (original_filename = get_original_filename(id))
          return path, original_filename
        end

        fd = FinalDestination.new(url)
        file = nil

        fd.get do |response, chunk, uri|
          if file.nil?
            check_response!(response, uri)
            original_filename = extract_filename_from_response(response, uri)
            file = File.open(path, "wb")
          end

          file.write(chunk)

          if file.size > MAX_FILE_SIZE
            file.close
            file.unlink
            file = nil
            throw :done
          end
        end

        if file
          file.close
          uploads_db.insert(
            "INSERT INTO downloads (id, original_filename) VALUES (?, ?)",
            [id, original_filename],
          )
          return path, original_filename
        end

        nil
      end

      def download_cache_path(id)
        id = id.gsub("/", "_").gsub("=", "-")
        File.join(settings[:download_cache_path], id)
      end

      def get_original_filename(id)
        uploads_db.db.query_single_splat("SELECT original_filename FROM downloads WHERE id = ?", id)
      end

      def check_response!(response, uri)
        if uri.blank?
          code = response.code.to_i

          if code >= 400
            raise "#{code} Error"
          else
            throw :done
          end
        end
      end

      def extract_filename_from_response(response, uri)
        filename =
          if (header = response.header["Content-Disposition"].presence)
            disposition_filename =
              header[/filename\*=UTF-8''(\S+)\b/i, 1] || header[/filename=(?:"(.+)"|[^\s;]+)/i, 1]
            if disposition_filename.present?
              URI.decode_www_form_component(disposition_filename)
            else
              nil
            end
          end

        filename = File.basename(uri.path).presence || "file" if filename.blank?

        if File.extname(filename).blank? && response.content_type.present?
          ext = MiniMime.lookup_by_content_type(response.content_type)&.extension
          filename = "#{filename}.#{ext}" if ext.present?
        end

        filename
      end

      def copy_to_tempfile(source_path)
        extension = File.extname(source_path)

        Tempfile.open(["discourse-upload", extension]) do |tmpfile|
          File.open(source_path, "rb") { |source_stream| IO.copy_stream(source_stream, tmpfile) }
          tmpfile.rewind
          yield(tmpfile)
        end
      end

      def log_status
        error_count_text = error_count > 0 ? "#{error_count} errors".red : "0 errors"
        print "\r%7d / %7d (%s, %s skipped)" %
                [current_count, @max_count, error_count_text, skipped_count]
      end
    end
  end
end
