# frozen_string_literal: true

require "rails_helper"

RSpec.describe MTGJSONAdapter do
  let(:catalog) { create(:catalog, :mtgjson) }
  let(:adapter) { described_class.new(catalog) }

  describe "inheritance" do
    it "inherits from CatalogAdapter" do
      expect(described_class).to be < CatalogAdapter
    end
  end

  describe "#initialize" do
    it "accepts a catalog parameter" do
      expect { described_class.new(catalog) }.not_to raise_error
    end

    it "stores the catalog" do
      expect(adapter.catalog).to eq(catalog)
    end
  end

  describe "#search" do
    it "delegates to MTGCard.search" do
      set = create(:mtg_set)
      card = create(:mtg_card, name: "Black Lotus", mtg_set: set)

      results = adapter.search("lotus")

      expect(results).to include(card)
    end

    it "supports limit option" do
      results = adapter.search("test", limit: 10)

      expect(results.limit_value).to eq(10)
    end
  end

  describe "#fetch_entry" do
    it "finds card by UUID" do
      set = create(:mtg_set)
      card = create(:mtg_card, uuid: "test-uuid-123", mtg_set: set)

      result = adapter.fetch_entry("test-uuid-123")

      expect(result).to eq(card)
    end

    it "returns nil for non-existent UUID" do
      result = adapter.fetch_entry("nonexistent")

      expect(result).to be_nil
    end
  end

  describe "#refresh" do
    it "returns the entry unchanged (placeholder)" do
      set = create(:mtg_set)
      card = create(:mtg_card, mtg_set: set)

      result = adapter.refresh(card)

      expect(result).to eq(card)
    end
  end

  describe "#bulk_import" do
    it "returns success statistics (placeholder)" do
      result = adapter.bulk_import

      expect(result[:success]).to be true
      expect(result).to have_key(:sets_imported)
      expect(result).to have_key(:cards_imported)
    end
  end
end
