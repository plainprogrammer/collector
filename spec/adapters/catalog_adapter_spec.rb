# frozen_string_literal: true

require "rails_helper"

RSpec.describe CatalogAdapter do
  let(:catalog) { create(:catalog) }
  let(:adapter) { described_class.new(catalog) }

  describe "#initialize" do
    it "accepts a catalog parameter" do
      expect { described_class.new(catalog) }.not_to raise_error
    end

    it "stores the catalog" do
      expect(adapter.catalog).to eq(catalog)
    end
  end

  describe "#search" do
    it "raises NotImplementedError" do
      expect { adapter.search("query") }.to raise_error(NotImplementedError)
    end
  end

  describe "#fetch_entry" do
    it "raises NotImplementedError" do
      expect { adapter.fetch_entry("identifier") }.to raise_error(NotImplementedError)
    end
  end

  describe "#refresh" do
    it "raises NotImplementedError" do
      entry = double("entry")
      expect { adapter.refresh(entry) }.to raise_error(NotImplementedError)
    end
  end

  describe "#bulk_import" do
    it "raises NotImplementedError" do
      expect { adapter.bulk_import }.to raise_error(NotImplementedError)
    end
  end
end
