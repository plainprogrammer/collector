require "rails_helper"

RSpec.describe Collection, type: :model do
  describe "validations" do
    it "is valid with valid attributes" do
      collection = Collection.new(name: "My MTG Collection")
      expect(collection).to be_valid
    end

    it "is invalid without a name" do
      collection = Collection.new(name: nil)
      expect(collection).not_to be_valid
      expect(collection.errors[:name]).to include("can't be blank")
    end
  end

  describe "associations" do
    it "has many storage_units" do
      association = described_class.reflect_on_association(:storage_units)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:destroy)
    end

    it "has many items" do
      association = described_class.reflect_on_association(:items)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:destroy)
    end
  end

  describe "database columns" do
    it "has expected columns" do
      expect(Collection.column_names).to include("id", "name", "description", "created_at", "updated_at")
    end
  end

  describe "#loose_items", :mtgjson do
    let(:collection) { create(:collection) }
    let(:storage_unit) { create(:storage_unit, collection: collection) }
    let(:card) { MTGJSON::Card.first }

    it "returns items without storage unit" do
      loose = create(:item, collection: collection, storage_unit: nil, card_uuid: card.uuid)
      stored = create(:item, collection: collection, storage_unit: storage_unit, card_uuid: card.uuid)

      expect(collection.loose_items).to include(loose)
      expect(collection.loose_items).not_to include(stored)
    end
  end

  describe "#loose_items_count", :mtgjson do
    let(:collection) { create(:collection) }
    let(:card) { MTGJSON::Card.first }

    it "returns count of unsorted items" do
      create_list(:item, 3, collection: collection, storage_unit: nil, card_uuid: card.uuid)
      expect(collection.loose_items_count).to eq(3)
    end
  end
end
