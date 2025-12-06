require "rails_helper"

RSpec.describe Item, type: :model do
  let(:collection) { Collection.create!(name: "Test Collection") }
  let(:storage_unit) { StorageUnit.create!(collection: collection, name: "Deck Box", storage_unit_type: :deck_box) }

  describe "validations" do
    it "is valid with valid attributes" do
      item = Item.new(
        collection: collection,
        card_uuid: "test-uuid-123",
        finish: :nonfoil,
        condition: :near_mint,
        language: "en"
      )
      expect(item).to be_valid
    end

    it "is invalid without a collection" do
      item = Item.new(
        card_uuid: "test-uuid",
        finish: :nonfoil,
        condition: :near_mint
      )
      expect(item).not_to be_valid
      expect(item.errors[:collection]).to include("must exist")
    end

    it "is invalid without a card_uuid" do
      item = Item.new(
        collection: collection,
        finish: :nonfoil,
        condition: :near_mint
      )
      expect(item).not_to be_valid
      expect(item.errors[:card_uuid]).to include("can't be blank")
    end

    it "is invalid without a finish" do
      item = Item.new(
        collection: collection,
        card_uuid: "test-uuid",
        condition: :near_mint
      )
      expect(item).not_to be_valid
      expect(item.errors[:finish]).to include("can't be blank")
    end

    it "is invalid without a condition" do
      item = Item.new(
        collection: collection,
        card_uuid: "test-uuid",
        finish: :nonfoil
      )
      expect(item).not_to be_valid
      expect(item.errors[:condition]).to include("can't be blank")
    end

    it "is invalid without a language" do
      item = Item.new(
        collection: collection,
        card_uuid: "test-uuid",
        finish: :nonfoil,
        condition: :near_mint,
        language: nil
      )
      expect(item).not_to be_valid
      expect(item.errors[:language]).to include("can't be blank")
    end

    it "is invalid with language not exactly 2 characters" do
      item = Item.new(
        collection: collection,
        card_uuid: "test-uuid",
        finish: :nonfoil,
        condition: :near_mint,
        language: "eng"
      )
      expect(item).not_to be_valid
      expect(item.errors[:language]).to include("is the wrong length (should be 2 characters)")
    end

    describe "grading_score validation" do
      it "accepts valid grading scores" do
        item = Item.new(
          collection: collection,
          card_uuid: "test-uuid",
          finish: :nonfoil,
          condition: :near_mint,
          grading_score: 9.5
        )
        expect(item).to be_valid
      end

      it "rejects grading scores below 0" do
        item = Item.new(
          collection: collection,
          card_uuid: "test-uuid",
          finish: :nonfoil,
          condition: :near_mint,
          grading_score: -1.0
        )
        expect(item).not_to be_valid
        expect(item.errors[:grading_score]).to include("must be greater than or equal to 0.0")
      end

      it "rejects grading scores above 10" do
        item = Item.new(
          collection: collection,
          card_uuid: "test-uuid",
          finish: :nonfoil,
          condition: :near_mint,
          grading_score: 11.0
        )
        expect(item).not_to be_valid
        expect(item.errors[:grading_score]).to include("must be less than or equal to 10.0")
      end

      it "allows nil grading_score" do
        item = Item.new(
          collection: collection,
          card_uuid: "test-uuid",
          finish: :nonfoil,
          condition: :near_mint,
          grading_score: nil
        )
        expect(item).to be_valid
      end
    end
  end

  describe "associations" do
    it "belongs to collection" do
      association = described_class.reflect_on_association(:collection)
      expect(association.macro).to eq(:belongs_to)
    end

    it "belongs to storage_unit (optional)" do
      association = described_class.reflect_on_association(:storage_unit)
      expect(association.macro).to eq(:belongs_to)
      expect(association.options[:optional]).to be true
    end
  end

  describe "enums" do
    it "defines finish enum" do
      expect(Item.finishes).to eq({
        "nonfoil" => 0,
        "traditional_foil" => 1,
        "etched" => 2,
        "glossy" => 3,
        "textured" => 4,
        "surge_foil" => 5
      })
    end

    it "defines condition enum" do
      expect(Item.conditions).to eq({
        "near_mint" => 0,
        "lightly_played" => 1,
        "moderately_played" => 2,
        "heavily_played" => 3,
        "damaged" => 4
      })
    end

    it "allows creating items with different finishes" do
      item = Item.create!(
        collection: collection,
        card_uuid: "test-uuid",
        finish: :traditional_foil,
        condition: :near_mint
      )
      expect(item.traditional_foil?).to be true
      expect(item.nonfoil?).to be false
    end

    it "allows creating items with different conditions" do
      item = Item.create!(
        collection: collection,
        card_uuid: "test-uuid",
        finish: :nonfoil,
        condition: :lightly_played
      )
      expect(item.lightly_played?).to be true
      expect(item.near_mint?).to be false
    end
  end

  describe "optional storage_unit" do
    it "allows items without a storage_unit (loose cards)" do
      item = Item.create!(
        collection: collection,
        card_uuid: "test-uuid",
        finish: :nonfoil,
        condition: :near_mint,
        storage_unit: nil
      )
      expect(item.storage_unit).to be_nil
      expect(item).to be_valid
    end

    it "allows items with a storage_unit" do
      item = Item.create!(
        collection: collection,
        storage_unit: storage_unit,
        card_uuid: "test-uuid",
        finish: :nonfoil,
        condition: :near_mint
      )
      expect(item.storage_unit).to eq(storage_unit)
    end
  end

  describe "#card method" do
    it "responds to card method" do
      item = Item.new(
        collection: collection,
        card_uuid: "test-uuid",
        finish: :nonfoil,
        condition: :near_mint
      )
      expect(item).to respond_to(:card)
    end

    it "returns nil when card_uuid is not found in MTGJSON" do
      skip "MTGJSON database not available" unless MTGJSON::Card.table_exists?

      item = Item.create!(
        collection: collection,
        card_uuid: "non-existent-uuid",
        finish: :nonfoil,
        condition: :near_mint
      )
      expect(item.card).to be_nil
    end

    # This test will only work if MTGJSON database is available
    it "returns MTGJSON::Card when card_uuid exists", skip: "Requires MTGJSON database" do
      # This would require seeding MTGJSON data or using a real card UUID
      # item.card should return an MTGJSON::Card instance
    end
  end

  describe "database columns" do
    it "has expected columns" do
      expect(Item.column_names).to include(
        "id", "collection_id", "storage_unit_id", "card_uuid",
        "finish", "language", "condition",
        "signed", "altered", "misprint",
        "grading_service", "grading_score",
        "acquisition_date", "acquisition_price",
        "notes", "created_at", "updated_at"
      )
    end
  end

  describe "default values" do
    it "defaults language to 'en'" do
      item = Item.new(
        collection: collection,
        card_uuid: "test-uuid",
        finish: :nonfoil,
        condition: :near_mint
      )
      expect(item.language).to eq("en")
    end

    it "defaults signed to false" do
      item = Item.create!(
        collection: collection,
        card_uuid: "test-uuid",
        finish: :nonfoil,
        condition: :near_mint
      )
      expect(item.signed).to be false
    end

    it "defaults altered to false" do
      item = Item.create!(
        collection: collection,
        card_uuid: "test-uuid",
        finish: :nonfoil,
        condition: :near_mint
      )
      expect(item.altered).to be false
    end

    it "defaults misprint to false" do
      item = Item.create!(
        collection: collection,
        card_uuid: "test-uuid",
        finish: :nonfoil,
        condition: :near_mint
      )
      expect(item.misprint).to be false
    end
  end

  describe "variant tracking" do
    it "tracks all variant attributes" do
      item = Item.create!(
        collection: collection,
        card_uuid: "test-uuid",
        finish: :etched,
        language: "ja",
        condition: :near_mint,
        signed: true,
        altered: false,
        misprint: true,
        grading_service: "PSA",
        grading_score: 9.5,
        acquisition_date: Date.new(2024, 1, 15),
        acquisition_price: 49.99,
        notes: "Bought at local game store"
      )

      expect(item.finish).to eq("etched")
      expect(item.language).to eq("ja")
      expect(item.condition).to eq("near_mint")
      expect(item.signed).to be true
      expect(item.altered).to be false
      expect(item.misprint).to be true
      expect(item.grading_service).to eq("PSA")
      expect(item.grading_score).to eq(9.5)
      expect(item.acquisition_date).to eq(Date.new(2024, 1, 15))
      expect(item.acquisition_price).to eq(49.99)
      expect(item.notes).to eq("Bought at local game store")
    end
  end

  describe "storage_unit_belongs_to_collection validation" do
    let(:other_collection) { Collection.create!(name: "Other Collection") }
    let(:storage_unit) { StorageUnit.create!(name: "Box A", collection: collection, storage_unit_type: :box) }
    let(:other_storage_unit) { StorageUnit.create!(name: "Box B", collection: other_collection, storage_unit_type: :box) }

    it "allows items without a storage unit" do
      item = Item.new(
        collection: collection,
        card_uuid: "test-uuid",
        condition: :near_mint,
        finish: :nonfoil,
        language: "en",
        storage_unit: nil
      )
      expect(item).to be_valid
    end

    it "allows items with a storage unit from the same collection" do
      item = Item.new(
        collection: collection,
        card_uuid: "test-uuid",
        condition: :near_mint,
        finish: :nonfoil,
        language: "en",
        storage_unit: storage_unit
      )
      expect(item).to be_valid
    end

    it "rejects items with a storage unit from a different collection" do
      item = Item.new(
        collection: collection,
        card_uuid: "test-uuid",
        condition: :near_mint,
        finish: :nonfoil,
        language: "en",
        storage_unit: other_storage_unit
      )
      expect(item).not_to be_valid
      expect(item.errors[:storage_unit]).to include("must belong to the same collection as the item")
    end
  end

  describe "#move_to_collection!" do
    let(:other_collection) { Collection.create!(name: "Other Collection") }
    let(:storage_unit) { StorageUnit.create!(name: "Box A", collection: collection, storage_unit_type: :box) }
    let(:other_storage_unit) { StorageUnit.create!(name: "Box B", collection: other_collection, storage_unit_type: :box) }
    let(:item) do
      Item.create!(
        collection: collection,
        storage_unit: storage_unit,
        card_uuid: "test-uuid",
        condition: :near_mint,
        finish: :nonfoil,
        language: "en"
      )
    end

    it "moves item to a new collection" do
      item.move_to_collection!(other_collection)

      expect(item.collection).to eq(other_collection)
    end

    it "clears storage unit when moving to a new collection" do
      item.move_to_collection!(other_collection)

      expect(item.storage_unit).to be_nil
    end

    it "can assign a new storage unit from the new collection" do
      item.move_to_collection!(other_collection, new_storage_unit: other_storage_unit)

      expect(item.collection).to eq(other_collection)
      expect(item.storage_unit).to eq(other_storage_unit)
    end

    it "raises error if new storage unit belongs to wrong collection" do
      expect {
        item.move_to_collection!(collection, new_storage_unit: other_storage_unit)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
