# frozen_string_literal: true

require "rails_helper"

RSpec.describe MTGCard, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:mtg_set) }
    # Skipped until Item model is created in Phase 0.4
    # it { is_expected.to have_many(:items).with_foreign_key(:catalog_entry_id) }
  end

  describe "validations" do
    subject { create(:mtg_card) }

    it { is_expected.to validate_presence_of(:uuid) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:set_code) }
    it { is_expected.to validate_presence_of(:collector_number) }
    it { is_expected.to validate_uniqueness_of(:uuid) }
    it { is_expected.to validate_uniqueness_of(:scryfall_id).allow_nil }
  end

  describe "UUID generation" do
    it "generates a UUID for id before creation" do
      card = create(:mtg_card)

      expect(card.id).to be_present
      expect(card.id).to match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i)
    end

    it "does not overwrite manually set id" do
      custom_id = SecureRandom.uuid
      card = create(:mtg_card, id: custom_id)

      expect(card.id).to eq(custom_id)
    end
  end

  describe "CatalogEntryInterface compliance" do
    let(:card) { create(:mtg_card, uuid: "test-uuid-123", name: "Lightning Bolt") }

    describe "#identifier" do
      it "returns the uuid" do
        expect(card.identifier).to eq("test-uuid-123")
      end
    end

    describe "#display_name" do
      it "returns the name" do
        expect(card.display_name).to eq("Lightning Bolt")
      end
    end

    describe "#image_url" do
      context "with scryfall_id" do
        let(:card) { create(:mtg_card, scryfall_id: "abc123") }

        it "constructs Scryfall CDN URL" do
          url = card.image_url(:normal)
          expect(url).to include("cards.scryfall.io")
          expect(url).to include("normal")
          expect(url).to include("abc123")
        end

        it "supports different sizes" do
          expect(card.image_url(:small)).to include("small")
          expect(card.image_url(:large)).to include("large")
        end

        it "defaults to normal size" do
          expect(card.image_url).to include("normal")
        end
      end

      context "without scryfall_id" do
        let(:card) { create(:mtg_card, scryfall_id: nil) }

        it "returns nil" do
          expect(card.image_url).to be_nil
        end
      end
    end
  end

  describe "default values" do
    it "defaults colors to empty array" do
      card = MTGCard.create!(
        mtg_set: create(:mtg_set),
        uuid: SecureRandom.uuid,
        name: "Test Card",
        set_code: "TST",
        collector_number: "1"
      )

      expect(card.colors).to eq([])
    end

    it "defaults finishes to empty array" do
      card = MTGCard.create!(
        mtg_set: create(:mtg_set),
        uuid: SecureRandom.uuid,
        name: "Test Card",
        set_code: "TST",
        collector_number: "2"
      )

      expect(card.finishes).to eq([])
    end
  end
end
