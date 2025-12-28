# frozen_string_literal: true

require "rails_helper"

RSpec.describe Catalog, type: :model do
  describe "validations" do
    it "requires name to be present" do
      catalog = described_class.new(source_type: "mtgjson", source_config: {})
      expect(catalog).not_to be_valid
      expect(catalog.errors[:name]).to include("can't be blank")
    end

    it "requires source_type to be present" do
      catalog = described_class.new(name: "Test", source_config: {})
      expect(catalog).not_to be_valid
      expect(catalog.errors[:source_type]).to include("can't be blank")
    end

    describe "source_type inclusion" do
      it "allows valid source types" do
        %w[mtgjson api custom].each do |type|
          catalog = described_class.new(
            name: "Test Catalog",
            source_type: type,
            source_config: {}
          )
          expect(catalog).to be_valid
        end
      end

      it "rejects invalid source types" do
        catalog = described_class.new(
          name: "Test Catalog",
          source_type: "invalid_type",
          source_config: {}
        )
        expect(catalog).not_to be_valid
        expect(catalog.errors[:source_type]).to include("is not included in the list")
      end
    end
  end

  describe "UUID primary key" do
    it "generates a UUID for id before validation" do
      catalog = described_class.new(
        name: "Test Catalog",
        source_type: "mtgjson",
        source_config: {}
      )
      catalog.valid?
      expect(catalog.id).to be_present
      expect(catalog.id).to match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/)
    end

    it "does not override an existing id" do
      existing_id = SecureRandom.uuid
      catalog = described_class.new(
        id: existing_id,
        name: "Test Catalog",
        source_type: "mtgjson",
        source_config: {}
      )
      catalog.valid?
      expect(catalog.id).to eq(existing_id)
    end
  end

  describe "#source_config" do
    it "defaults to empty hash" do
      catalog = described_class.new(
        name: "Test Catalog",
        source_type: "mtgjson"
      )
      expect(catalog.source_config).to eq({})
    end

    it "accepts hash values" do
      config = { "version" => "5.2.2", "url" => "https://example.com" }
      catalog = described_class.new(
        name: "Test Catalog",
        source_type: "mtgjson",
        source_config: config
      )
      expect(catalog.source_config).to eq(config)
    end
  end
end
