# frozen_string_literal: true

require "rails_helper"

RSpec.describe Raif::MigrationChecker do
  describe ".uninstalled_migrations" do
    before do
      # Mock engine migration files
      allow(described_class).to receive(:engine_migration_files).and_return([
        "20250224234252_create_raif_tables.rb",
        "20250421202149_add_response_format_to_raif_conversations.rb",
        "20250424200755_add_cost_columns_to_raif_model_completions.rb"
      ])
    end

    context "when all migrations are installed" do
      before do
        allow(described_class).to receive(:host_migration_files).and_return([
          "20250101000000_create_raif_tables.raif.rb",
          "20250102000000_add_response_format_to_raif_conversations.raif.rb",
          "20250103000000_add_cost_columns_to_raif_model_completions.raif.rb"
        ])
      end

      it "returns an empty array" do
        expect(described_class.uninstalled_migrations).to be_empty
      end
    end

    context "when some migrations are missing" do
      before do
        allow(described_class).to receive(:host_migration_files).and_return([
          "20250101000000_create_raif_tables.raif.rb"
        ])
      end

      it "returns the missing migrations" do
        uninstalled = described_class.uninstalled_migrations
        expect(uninstalled).to include("20250421202149_add_response_format_to_raif_conversations.rb")
        expect(uninstalled).to include("20250424200755_add_cost_columns_to_raif_model_completions.rb")
        expect(uninstalled).not_to include("20250224234252_create_raif_tables.rb")
      end
    end

    context "when no migrations are installed" do
      before do
        allow(described_class).to receive(:host_migration_files).and_return([])
      end

      it "returns all engine migrations" do
        uninstalled = described_class.uninstalled_migrations
        expect(uninstalled.size).to eq(3)
        expect(uninstalled).to include("20250224234252_create_raif_tables.rb")
        expect(uninstalled).to include("20250421202149_add_response_format_to_raif_conversations.rb")
        expect(uninstalled).to include("20250424200755_add_cost_columns_to_raif_model_completions.rb")
      end
    end
  end

  describe ".check_and_warn!" do
    context "when there are uninstalled migrations" do
      before do
        allow(described_class).to receive(:uninstalled_migrations).and_return([
          "20250224234252_create_raif_tables.rb"
        ])
        allow(Rails).to receive(:logger).and_return(double("logger", warn: nil))
      end

      it "outputs a warning" do
        expect { described_class.check_and_warn! }.to output(/RAIF MIGRATION WARNING/).to_stderr
      end

      it "logs a warning" do
        expect(Rails.logger).to receive(:warn).with(/RAIF MIGRATION WARNING/)
        described_class.check_and_warn!
      end
    end

    context "when all migrations are installed" do
      before do
        allow(described_class).to receive(:uninstalled_migrations).and_return([])
      end

      it "does not output a warning" do
        expect { described_class.check_and_warn! }.not_to output.to_stderr
      end
    end
  end

  describe ".extract_migration_name" do
    it "extracts migration name without timestamp" do
      expect(described_class.send(:extract_migration_name, "20250224234252_create_raif_tables.rb"))
        .to eq("create_raif_tables")
    end

    it "extracts migration name from .raif.rb files" do
      expect(described_class.send(:extract_migration_name, "20250529142730_create_raif_tables.raif.rb"))
        .to eq("create_raif_tables")
    end
  end

  describe ".migrations_match?" do
    it "returns true when migration names match despite different timestamps" do
      engine_migration = "20250224234252_create_raif_tables.rb"
      host_migration = "20250101000000_create_raif_tables.rb"

      expect(described_class.send(:migrations_match?, engine_migration, host_migration)).to be true
    end

    it "returns true when comparing engine .rb with host .raif.rb files" do
      engine_migration = "20250224234252_create_raif_tables.rb"
      host_migration = "20250529142730_create_raif_tables.raif.rb"

      expect(described_class.send(:migrations_match?, engine_migration, host_migration)).to be true
    end

    it "returns false when migration names don't match" do
      engine_migration = "20250224234252_create_raif_tables.rb"
      host_migration = "20250101000000_add_some_column.rb"

      expect(described_class.send(:migrations_match?, engine_migration, host_migration)).to be false
    end
  end
end
