# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Catalog adapter integration" do
  describe "#adapter" do
    context "with mtgjson source_type" do
      let(:catalog) { create(:catalog, source_type: "mtgjson") }

      it "returns a MtgjsonAdapter instance" do
        expect(catalog.adapter).to be_a(MtgjsonAdapter)
      end

      it "passes the catalog to the adapter" do
        adapter = catalog.adapter
        expect(adapter.catalog).to eq(catalog)
      end
    end

    context "with api source_type" do
      let(:catalog) { create(:catalog, source_type: "api") }

      it "raises NotImplementedError for unimplemented adapter types" do
        expect { catalog.adapter }.to raise_error(NotImplementedError, /ApiAdapter not yet implemented/)
      end
    end

    context "with custom source_type" do
      let(:catalog) { create(:catalog, source_type: "custom") }

      it "raises NotImplementedError for unimplemented adapter types" do
        expect { catalog.adapter }.to raise_error(NotImplementedError, /CustomAdapter not yet implemented/)
      end
    end

    context "with unknown source_type" do
      it "cannot be created due to validation" do
        catalog = build(:catalog, source_type: "unknown")
        expect(catalog).not_to be_valid
        expect(catalog.errors[:source_type]).to include("is not included in the list")
      end
    end
  end
end
