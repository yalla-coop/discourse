# frozen_string_literal: true

require "date"
require "extralite"
require "ipaddr"

module Migrations
  module Database
    INTERMEDIATE_DB_SCHEMA_PATH = File.join(::Migrations.root_path, "db", "intermediate_db_schema")
    UPLOADS_DB_SCHEMA_PATH = File.join(::Migrations.root_path, "db", "uploads_db_schema")

    module_function

    def migrate(db_path, migrations_path:)
      Migrator.new(db_path).migrate(migrations_path)
    end

    def reset!(db_path)
      Migrator.new(db_path).reset!
    end

    def connect(path)
      connection = Connection.new(path:)
      return connection unless block_given?

      begin
        yield(connection)
      ensure
        connection.close
      end
      nil
    end

    def format_datetime(value)
      value&.utc&.iso8601
    end

    def format_date(value)
      value&.to_date&.iso8601
    end

    def format_boolean(value)
      return nil if value.nil?
      value ? 1 : 0
    end

    def format_ip_address(value)
      return nil if value.blank?
      IPAddr.new(value).to_s
    rescue ArgumentError
      nil
    end

    def to_blob(value)
      return nil if value.blank?
      Extralite::Blob.new(value)
    end
  end
end
