# frozen_string_literal: true

require "rails_helper"

RSpec.describe MtgjsonAdapter do
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
    it "raises NotImplementedError (placeholder for Phase 0.3)" do
      expect { adapter.search("Black Lotus") }.to raise_error(NotImplementedError)
    end
  end

  describe "#fetch_entry" do
    it "raises NotImplementedError (placeholder for Phase 0.3)" do
      expect { adapter.fetch_entry("some-uuid") }.to raise_error(NotImplementedError)
    end
  end

  describe "#refresh" do
    it "raises NotImplementedError (placeholder for Phase 0.3)" do
      entry = double("entry")
      expect { adapter.refresh(entry) }.to raise_error(NotImplementedError)
    end
  end

  describe "#bulk_import" do
    it "raises NotImplementedError (placeholder for Phase 0.3)" do
      expect { adapter.bulk_import }.to raise_error(NotImplementedError)
    end
  end
end
