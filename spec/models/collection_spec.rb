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
end
