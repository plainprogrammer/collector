require "rails_helper"

RSpec.describe CollectionStatistics, :mtgjson do
  let(:collection) { create(:collection) }
  let(:card1) { MTGJSON::Card.first }
  let(:card2) { MTGJSON::Card.second }

  subject { described_class.new(collection) }

  describe "#total_count" do
    it "returns total number of items" do
      create_list(:item, 5, collection: collection, card_uuid: card1.uuid)
      expect(subject.total_count).to eq(5)
    end

    it "returns 0 for empty collection" do
      expect(subject.total_count).to eq(0)
    end
  end

  describe "#unique_count" do
    it "returns count of unique cards" do
      create_list(:item, 3, collection: collection, card_uuid: card1.uuid)
      create_list(:item, 2, collection: collection, card_uuid: card2.uuid)

      expect(subject.unique_count).to eq(2)
    end

    it "returns 0 for empty collection" do
      expect(subject.unique_count).to eq(0)
    end
  end

  describe "#average_copies" do
    it "calculates average copies per card" do
      create_list(:item, 4, collection: collection, card_uuid: card1.uuid)
      create_list(:item, 2, collection: collection, card_uuid: card2.uuid)

      expect(subject.average_copies).to eq(3.0)
    end

    it "returns 0 for empty collection" do
      expect(subject.average_copies).to eq(0)
    end
  end

  describe "#condition_breakdown" do
    it "groups items by condition" do
      create_list(:item, 3, collection: collection, card_uuid: card1.uuid, condition: :near_mint)
      create_list(:item, 2, collection: collection, card_uuid: card1.uuid, condition: :lightly_played)

      breakdown = subject.condition_breakdown
      expect(breakdown["near_mint"]).to eq(3)
      expect(breakdown["lightly_played"]).to eq(2)
    end
  end

  describe "#finish_breakdown" do
    it "groups items by finish" do
      create_list(:item, 4, collection: collection, card_uuid: card1.uuid, finish: :nonfoil)
      create_list(:item, 1, collection: collection, card_uuid: card1.uuid, finish: :traditional_foil)

      breakdown = subject.finish_breakdown
      expect(breakdown["nonfoil"]).to eq(4)
      expect(breakdown["traditional_foil"]).to eq(1)
    end
  end

  describe "#foil_count" do
    it "counts non-nonfoil items" do
      create_list(:item, 3, collection: collection, card_uuid: card1.uuid, finish: :nonfoil)
      create_list(:item, 2, collection: collection, card_uuid: card1.uuid, finish: :traditional_foil)
      create(:item, collection: collection, card_uuid: card1.uuid, finish: :etched)

      expect(subject.foil_count).to eq(3)
    end
  end

  describe "#foil_percentage" do
    it "calculates foil percentage" do
      create_list(:item, 8, collection: collection, card_uuid: card1.uuid, finish: :nonfoil)
      create_list(:item, 2, collection: collection, card_uuid: card1.uuid, finish: :traditional_foil)

      expect(subject.foil_percentage).to eq(20.0)
    end

    it "returns 0 for empty collection" do
      expect(subject.foil_percentage).to eq(0)
    end
  end

  describe "#set_breakdown" do
    it "groups items by set code" do
      create(:item, collection: collection, card_uuid: card1.uuid)
      create(:item, collection: collection, card_uuid: card2.uuid)

      breakdown = subject.set_breakdown
      expect(breakdown).to be_a(Hash)
      expect(breakdown.values.sum).to eq(2)
    end

    it "sorts by count descending" do
      # Create more items for card1 than card2 to test sorting
      create_list(:item, 3, collection: collection, card_uuid: card1.uuid)
      create(:item, collection: collection, card_uuid: card2.uuid)

      breakdown = subject.set_breakdown
      counts = breakdown.values
      expect(counts).to eq(counts.sort.reverse)
    end
  end

  describe "#color_breakdown" do
    it "includes all color categories" do
      create(:item, collection: collection, card_uuid: card1.uuid)

      breakdown = subject.color_breakdown
      expect(breakdown.keys).to include("W", "U", "B", "R", "G", "Colorless", "Multicolor")
    end
  end

  describe "#type_breakdown" do
    it "groups items by card type" do
      create(:item, collection: collection, card_uuid: card1.uuid)

      breakdown = subject.type_breakdown
      expect(breakdown).to be_a(Hash)
    end

    it "sorts by count descending" do
      create_list(:item, 5, collection: collection, card_uuid: card1.uuid)

      breakdown = subject.type_breakdown
      counts = breakdown.values
      expect(counts).to eq(counts.sort.reverse)
    end
  end

  describe "#rarity_breakdown" do
    it "groups items by rarity" do
      create(:item, collection: collection, card_uuid: card1.uuid)

      breakdown = subject.rarity_breakdown
      expect(breakdown).to be_a(Hash)
      expect(breakdown.values.sum).to eq(1)
    end
  end
end
