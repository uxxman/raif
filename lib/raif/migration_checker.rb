# frozen_string_literal: true

module Raif
  module MigrationChecker
    class << self
      def uninstalled_migrations
        engine_migrations = engine_migration_files
        host_migrations = host_migration_files

        engine_migrations.reject do |engine_migration|
          host_migrations.any?{|host_migration| migrations_match?(engine_migration, host_migration) }
        end
      end

      def check_and_warn!
        return unless defined?(Rails) && Rails.application

        uninstalled = uninstalled_migrations
        return if uninstalled.empty?

        warning_message = build_warning_message(uninstalled)

        # Output to both logger and STDOUT to ensure visibility
        Rails.logger&.warn(warning_message)
        warn warning_message
      end

    private

      def engine_migration_files
        migration_dir = File.join(Raif::Engine.root, "db", "migrate")
        return [] unless Dir.exist?(migration_dir)

        Dir.glob(File.join(migration_dir, "*.rb")).map do |file|
          File.basename(file)
        end.sort
      end

      def host_migration_files
        return [] unless defined?(Rails) && Rails.application

        migration_dir = Rails.application.paths["db/migrate"].first
        return [] unless migration_dir && Dir.exist?(migration_dir)

        # Look for both .raif.rb and .rb files that contain 'raif' in the name
        raif_files = Dir.glob(File.join(migration_dir, "*raif*.rb"))
        raif_files.map do |file|
          File.basename(file)
        end.sort
      end

      def migrations_match?(engine_migration, host_migration)
        # Extract the migration name without timestamp
        engine_name = extract_migration_name(engine_migration)
        host_name = extract_migration_name(host_migration)

        engine_name == host_name
      end

      def extract_migration_name(filename)
        # Remove timestamp and .rb/.raif.rb extension
        # e.g., "20250224234252_create_raif_tables.rb" -> "create_raif_tables"
        # e.g., "20250529142730_create_raif_tables.raif.rb" -> "create_raif_tables"
        filename.gsub(/^\d+_/, "").gsub(/\.raif\.rb$/, "").gsub(/\.rb$/, "")
      end

      def build_warning_message(uninstalled_migrations)
        <<~WARNING
          \e[33m
          ⚠️  RAIF MIGRATION WARNING ⚠️

          The following Raif migrations have not been installed in your application:

          #{uninstalled_migrations.map{|m| "  • #{m}" }.join("\n")}

          To install these migrations, run:

            rails raif:install:migrations
            rails db:migrate

          \e[0m
        WARNING
      end
    end
  end
end
