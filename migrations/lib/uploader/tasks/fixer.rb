# frozen_string_literal: true

module Migrations::Uploader
  module Tasks
    class Fixer < Base
      def run!
        return if max_count.zero?

        puts "Fixing missing uploads..."

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

      def max_count
        @max_count ||=
          uploads_db.db.query_single_splat("SELECT COUNT(*) FROM uploads WHERE upload IS NOT NULL")
      end

      def enqueue_jobs
        uploads_db
          .db
          .query(
            "SELECT id, upload FROM uploads WHERE upload IS NOT NULL ORDER BY rowid DESC",
          ) { |row| work_queue << row }
      end

      def instantiate_task_resource
        OpenStruct.new(url: "")
      end

      def handle_status_update(result)
        @current_count += 1

        case result[:status]
        when :ok
          # ignore
        when :error
          @error_count += 1
          puts " Error in #{result[:id]}"
        when :missing
          @missing_count += 1
          puts " Missing #{result[:id]}"

          uploads_db.db.execute("DELETE FROM uploads WHERE id = ?", result[:id])
          Upload.delete_by(id: result[:upload_id])
        end
      end

      def process_upload(row, fake_upload)
        upload = JSON.parse(row[:upload], symbolize_names: true)
        fake_upload.url = upload[:url]
        path = add_multisite_prefix(discourse_store.get_path_for_upload(fake_upload))

        status = file_exists?(path) ? :ok : :missing

        update_status_queue(row, upload, status)
      rescue StandardError => error
        puts error.message
        status = :error
        update_status_queue(row, upload, status)
      end

      def update_status_queue(row, upload, status)
        status_queue << { id: row[:id], upload_id: upload[:id], status: status }
      end

      def log_status
        error_count_text = error_count > 0 ? "#{error_count} errors".red : "0 errors"
        print "\r%7d / %7d (%s, %s missing)" %
                [current_count, max_count, error_count_text, missing_count]
      end
    end
  end
end
