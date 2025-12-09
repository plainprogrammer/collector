require "rails_helper"

RSpec.describe StorageUnit, type: :model do
  let(:collection) { Collection.create!(name: "Test Collection") }

  describe "validations" do
    it "is valid with valid attributes" do
      storage_unit = StorageUnit.new(
        collection: collection,
        name: "Deck Box",
        storage_unit_type: :deck_box
      )
      expect(storage_unit).to be_valid
    end

    it "is invalid without a name" do
      storage_unit = StorageUnit.new(
        collection: collection,
        storage_unit_type: :box
      )
      expect(storage_unit).not_to be_valid
      expect(storage_unit.errors[:name]).to include("can't be blank")
    end

    it "is invalid without a storage_unit_type" do
      storage_unit = StorageUnit.new(
        collection: collection,
        name: "Box"
      )
      expect(storage_unit).not_to be_valid
      expect(storage_unit.errors[:storage_unit_type]).to include("can't be blank")
    end

    it "is invalid without a collection" do
      storage_unit = StorageUnit.new(
        name: "Box",
        storage_unit_type: :box
      )
      expect(storage_unit).not_to be_valid
      expect(storage_unit.errors[:collection]).to include("must exist")
    end

    describe "circular nesting prevention" do
      it "prevents a storage unit from being its own parent" do
        storage_unit = StorageUnit.create!(
          collection: collection,
          name: "Box",
          storage_unit_type: :box
        )
        storage_unit.parent_id = storage_unit.id
        expect(storage_unit).not_to be_valid
        expect(storage_unit.errors[:parent_id]).to include("cannot be the same as the storage unit itself")
      end

      it "prevents circular references in the parent chain" do
        unit_a = StorageUnit.create!(
          collection: collection,
          name: "Box A",
          storage_unit_type: :box
        )
        unit_b = StorageUnit.create!(
          collection: collection,
          name: "Box B",
          storage_unit_type: :box,
          parent: unit_a
        )
        unit_c = StorageUnit.create!(
          collection: collection,
          name: "Box C",
          storage_unit_type: :box,
          parent: unit_b
        )

        # Try to make unit_a a child of unit_c (creating a circle)
        unit_a.parent = unit_c
        expect(unit_a).not_to be_valid
        expect(unit_a.errors[:parent_id]).to include("creates a circular reference")
      end
    end
  end

  describe "associations" do
    it "belongs to collection" do
      association = described_class.reflect_on_association(:collection)
      expect(association.macro).to eq(:belongs_to)
    end

    it "belongs to parent (optional)" do
      association = described_class.reflect_on_association(:parent)
      expect(association.macro).to eq(:belongs_to)
      expect(association.options[:class_name]).to eq("StorageUnit")
      expect(association.options[:optional]).to be true
    end

    it "has many children" do
      association = described_class.reflect_on_association(:children)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:class_name]).to eq("StorageUnit")
      expect(association.options[:foreign_key]).to eq(:parent_id)
      expect(association.options[:dependent]).to eq(:destroy)
    end

    it "has many items" do
      association = described_class.reflect_on_association(:items)
      expect(association.macro).to eq(:has_many)
      expect(association.options[:dependent]).to eq(:nullify)
    end
  end

  describe "enums" do
    it "defines storage_unit_type enum" do
      expect(StorageUnit.storage_unit_types).to eq({
        "box" => 0,
        "binder" => 1,
        "deck" => 2,
        "deck_box" => 3,
        "portfolio" => 4,
        "toploader_case" => 5,
        "loose" => 6,
        "other" => 99
      })
    end

    it "allows creating units with different types" do
      unit = StorageUnit.create!(
        collection: collection,
        name: "My Deck",
        storage_unit_type: :deck
      )
      expect(unit.deck?).to be true
      expect(unit.box?).to be false
    end
  end

  describe "nesting behavior" do
    it "allows nesting storage units" do
      parent_box = StorageUnit.create!(
        collection: collection,
        name: "Main Box",
        storage_unit_type: :box
      )
      child_deck = StorageUnit.create!(
        collection: collection,
        name: "Commander Deck",
        storage_unit_type: :deck,
        parent: parent_box
      )

      expect(child_deck.parent).to eq(parent_box)
      expect(parent_box.children).to include(child_deck)
    end

    it "allows storage units without parents" do
      unit = StorageUnit.create!(
        collection: collection,
        name: "Standalone Binder",
        storage_unit_type: :binder
      )
      expect(unit.parent).to be_nil
    end
  end

  describe "database columns" do
    it "has expected columns" do
      expect(StorageUnit.column_names).to include(
        "id", "collection_id", "parent_id", "storage_unit_type",
        "name", "description", "location", "created_at", "updated_at"
      )
    end
  end

  describe "#total_items_count", :mtgjson do
    let(:card) { MTGJSON::Card.first }
    let(:parent) { create(:storage_unit, collection: collection) }
    let(:child) { create(:storage_unit, collection: collection, parent: parent) }

    it "counts direct items" do
      create_list(:item, 3, collection: collection, storage_unit: parent, card_uuid: card.uuid)
      expect(parent.total_items_count).to eq(3)
    end

    it "includes nested items in count" do
      create_list(:item, 2, collection: collection, storage_unit: parent, card_uuid: card.uuid)
      create_list(:item, 3, collection: collection, storage_unit: child, card_uuid: card.uuid)

      expect(parent.total_items_count).to eq(5)
    end

    it "handles deeply nested units" do
      grandchild = create(:storage_unit, collection: collection, parent: child)
      create(:item, collection: collection, storage_unit: grandchild, card_uuid: card.uuid)

      expect(parent.total_items_count).to eq(1)
    end
  end

  describe "#all_items", :mtgjson do
    let(:card) { MTGJSON::Card.first }
    let(:parent) { create(:storage_unit, collection: collection) }
    let(:child) { create(:storage_unit, collection: collection, parent: parent) }

    it "returns items from unit and children" do
      item1 = create(:item, collection: collection, storage_unit: parent, card_uuid: card.uuid)
      item2 = create(:item, collection: collection, storage_unit: child, card_uuid: card.uuid)

      expect(parent.all_items).to contain_exactly(item1, item2)
    end
  end

  describe "#ancestors" do
    let(:grandparent) { create(:storage_unit, collection: collection, name: "Grandparent") }
    let(:parent) { create(:storage_unit, collection: collection, parent: grandparent, name: "Parent") }
    let(:child) { create(:storage_unit, collection: collection, parent: parent, name: "Child") }

    it "returns empty array for root unit" do
      expect(grandparent.ancestors).to eq([])
    end

    it "returns parent for first level child" do
      expect(parent.ancestors).to eq([ grandparent ])
    end

    it "returns ancestors in order from root to immediate parent" do
      expect(child.ancestors).to eq([ grandparent, parent ])
    end
  end
end
