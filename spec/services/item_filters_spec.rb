require "rails_helper"

RSpec.describe ItemFilters do
  let(:collection) { create(:collection) }

  describe "#initialize" do
    it "accepts filter parameters" do
      filters = described_class.new(set: "MH3", color: "R", condition: "near_mint")

      expect(filters.set).to eq("MH3")
      expect(filters.color).to eq("R")
      expect(filters.condition).to eq("near_mint")
    end

    it "treats blank strings as nil" do
      filters = described_class.new(set: "", color: nil)

      expect(filters.set).to be_nil
      expect(filters.color).to be_nil
    end
  end

  describe "#empty?" do
    it "returns true with no filters" do
      filters = described_class.new({})
      expect(filters.empty?).to be true
    end

    it "returns true with all blank filters" do
      filters = described_class.new(set: "", color: "", type: "")
      expect(filters.empty?).to be true
    end

    it "returns false with any filter set" do
      filters = described_class.new(set: "MH3")
      expect(filters.empty?).to be false
    end
  end

  describe "#to_h" do
    it "returns only non-blank filters" do
      filters = described_class.new(set: "MH3", color: "", condition: "near_mint", type: nil)

      expect(filters.to_h).to eq({ set: "MH3", condition: "near_mint" })
    end

    it "returns empty hash when no filters" do
      filters = described_class.new({})
      expect(filters.to_h).to eq({})
    end
  end

  describe "#active_count" do
    it "returns count of active filters" do
      filters = described_class.new(set: "MH3", condition: "near_mint")
      expect(filters.active_count).to eq(2)
    end

    it "returns 0 when no filters" do
      filters = described_class.new({})
      expect(filters.active_count).to eq(0)
    end
  end

  describe "#apply", :mtgjson do
    let(:card) { MTGJSON::Card.first }
    let(:cards) { { card.uuid => card } }

    context "with condition filter" do
      let!(:nm_item) { create(:item, collection: collection, card_uuid: card.uuid, condition: :near_mint) }
      let!(:lp_item) { create(:item, collection: collection, card_uuid: card.uuid, condition: :lightly_played) }

      it "filters by condition" do
        filters = described_class.new(condition: "near_mint")
        result = filters.apply(collection.items, cards: cards)

        expect(result).to include(nm_item)
        expect(result).not_to include(lp_item)
      end
    end

    context "with finish filter" do
      let!(:nonfoil_item) { create(:item, collection: collection, card_uuid: card.uuid, finish: :nonfoil) }
      let!(:foil_item) { create(:item, collection: collection, card_uuid: card.uuid, finish: :traditional_foil) }
      let!(:etched_item) { create(:item, collection: collection, card_uuid: card.uuid, finish: :etched) }

      it "filters by nonfoil" do
        filters = described_class.new(finish: "nonfoil")
        result = filters.apply(collection.items, cards: cards)

        expect(result).to include(nonfoil_item)
        expect(result).not_to include(foil_item)
        expect(result).not_to include(etched_item)
      end

      it "filters by any foil" do
        filters = described_class.new(finish: "foil")
        result = filters.apply(collection.items, cards: cards)

        expect(result).to include(foil_item)
        expect(result).to include(etched_item)
        expect(result).not_to include(nonfoil_item)
      end

      it "filters by specific foil type" do
        filters = described_class.new(finish: "etched")
        result = filters.apply(collection.items, cards: cards)

        expect(result).to include(etched_item)
        expect(result).not_to include(foil_item)
        expect(result).not_to include(nonfoil_item)
      end
    end

    context "with combined filters" do
      let!(:nm_foil) { create(:item, collection: collection, card_uuid: card.uuid, condition: :near_mint, finish: :traditional_foil) }
      let!(:nm_nonfoil) { create(:item, collection: collection, card_uuid: card.uuid, condition: :near_mint, finish: :nonfoil) }
      let!(:lp_foil) { create(:item, collection: collection, card_uuid: card.uuid, condition: :lightly_played, finish: :traditional_foil) }

      it "applies multiple filters with AND logic" do
        filters = described_class.new(condition: "near_mint", finish: "foil")
        result = filters.apply(collection.items, cards: cards)

        expect(result).to include(nm_foil)
        expect(result).not_to include(nm_nonfoil)
        expect(result).not_to include(lp_foil)
      end
    end

    context "when empty" do
      let!(:item) { create(:item, collection: collection, card_uuid: card.uuid) }

      it "returns all items" do
        filters = described_class.new({})
        result = filters.apply(collection.items, cards: cards)

        expect(result).to include(item)
      end
    end
  end
end
