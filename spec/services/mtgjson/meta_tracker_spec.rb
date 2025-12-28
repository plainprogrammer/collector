# frozen_string_literal: true

require "rails_helper"

RSpec.describe MTGJSON::MetaTracker do
  let(:catalog) { create(:catalog, source_type: "mtgjson", source_config: {}) }
  let(:tracker) { described_class.new(catalog) }

  describe "#current_version" do
    context "when no version is stored" do
      it "returns nil" do
        expect(tracker.current_version).to be_nil
      end
    end

    context "when version is stored in source_config" do
      before do
        catalog.update!(source_config: { version: "5.2.2", last_updated: "2024-01-15" })
      end

      it "returns the stored version" do
        expect(tracker.current_version).to eq("5.2.2")
      end
    end
  end

  describe "#update_version" do
    it "stores version in catalog source_config" do
      tracker.update_version("5.3.0")

      expect(catalog.reload.source_config["version"]).to eq("5.3.0")
    end

    it "stores timestamp of update" do
      travel_to Time.zone.local(2024, 1, 15, 12, 0, 0) do
        tracker.update_version("5.3.0")

        expect(catalog.reload.source_config["last_updated"]).to eq(Time.current.iso8601)
      end
    end

    it "preserves other source_config data" do
      catalog.update!(source_config: { url: "https://mtgjson.com", custom_field: "value" })

      tracker.update_version("5.3.0")

      config = catalog.reload.source_config
      expect(config["url"]).to eq("https://mtgjson.com")
      expect(config["custom_field"]).to eq("value")
      expect(config["version"]).to eq("5.3.0")
    end
  end

  describe "#needs_update?" do
    context "when no version is stored" do
      it "returns true" do
        expect(tracker.needs_update?("5.2.2")).to be true
      end
    end

    context "when stored version matches new version" do
      before do
        catalog.update!(source_config: { version: "5.2.2" })
      end

      it "returns false" do
        expect(tracker.needs_update?("5.2.2")).to be false
      end
    end

    context "when stored version differs from new version" do
      before do
        catalog.update!(source_config: { version: "5.2.1" })
      end

      it "returns true" do
        expect(tracker.needs_update?("5.2.2")).to be true
      end
    end
  end

  describe "#import_stats" do
    it "returns empty hash when no stats stored" do
      expect(tracker.import_stats).to eq({})
    end

    it "returns stored import stats" do
      catalog.update!(
        source_config: {
          import_stats: {
            sets_imported: 100,
            cards_imported: 80000,
            import_duration: 120.5
          }
        }
      )

      stats = tracker.import_stats
      expect(stats["sets_imported"]).to eq(100)
      expect(stats["cards_imported"]).to eq(80000)
    end
  end

  describe "#record_import_stats" do
    it "stores import statistics" do
      stats = {
        sets_imported: 100,
        cards_imported: 80000,
        import_duration: 120.5
      }

      tracker.record_import_stats(stats)

      expect(catalog.reload.source_config["import_stats"]).to eq(stats.stringify_keys)
    end

    it "preserves version information" do
      catalog.update!(source_config: { version: "5.2.2" })

      tracker.record_import_stats(sets_imported: 100)

      config = catalog.reload.source_config
      expect(config["version"]).to eq("5.2.2")
      expect(config["import_stats"]["sets_imported"]).to eq(100)
    end
  end
end
