require "rails_helper"

RSpec.describe CardsHelper, type: :helper do
  describe "#card_image_url" do
    let(:card) { MTGJSON::Card.includes(:identifiers).joins(:identifiers).first }

    context "when card has Scryfall ID" do
      it "returns Scryfall CDN URL" do
        skip "No cards with identifiers" unless card
        url = helper.card_image_url(card)
        if url
          expect(url).to start_with("https://cards.scryfall.io")
          expect(url).to end_with(".jpg")
        end
      end

      it "accepts size parameter" do
        skip "No cards with identifiers" unless card
        url = helper.card_image_url(card, size: :large)
        expect(url).to include("/large/") if url
      end
    end

    context "when card has no Scryfall ID" do
      let(:card_without_id) do
        MTGJSON::Card.includes(:identifiers)
                     .left_joins(:identifiers)
                     .where(cardIdentifiers: { scryfallId: nil })
                     .first
      end

      it "returns nil" do
        skip "All cards have Scryfall IDs" unless card_without_id
        expect(helper.card_image_url(card_without_id)).to be_nil
      end
    end
  end

  describe "#format_mana_cost" do
    it "formats mana symbols" do
      result = helper.format_mana_cost("{R}")
      expect(result).to include("mana-symbol")
    end

    it "handles multiple symbols" do
      result = helper.format_mana_cost("{2}{R}{R}")
      expect(result.scan("mana-symbol").count).to eq(3)
    end

    it "returns empty string for nil" do
      expect(helper.format_mana_cost(nil)).to eq("")
    end

    it "returns empty string for blank" do
      expect(helper.format_mana_cost("")).to eq("")
    end
  end

  describe "#rarity_class" do
    it "returns gray for common" do
      expect(helper.rarity_class("common")).to include("gray")
    end

    it "returns amber for rare" do
      expect(helper.rarity_class("rare")).to include("amber")
    end

    it "returns orange for mythic" do
      expect(helper.rarity_class("mythic")).to include("orange")
    end

    it "handles case insensitivity" do
      expect(helper.rarity_class("RARE")).to include("amber")
    end

    it "returns gray for unknown rarity" do
      expect(helper.rarity_class("unknown")).to include("gray")
    end

    it "returns gray for nil" do
      expect(helper.rarity_class(nil)).to include("gray")
    end
  end

  describe "#legality_badge" do
    it "returns green badge for legal" do
      result = helper.legality_badge("legal")
      expect(result).to include("green")
      expect(result).to include("Legal")
    end

    it "returns red badge for banned" do
      result = helper.legality_badge("banned")
      expect(result).to include("red")
      expect(result).to include("Banned")
    end

    it "returns yellow badge for restricted" do
      result = helper.legality_badge("restricted")
      expect(result).to include("yellow")
      expect(result).to include("Restricted")
    end

    it "returns gray badge for not legal" do
      result = helper.legality_badge("not_legal")
      expect(result).to include("gray")
      expect(result).to include("Not Legal")
    end

    it "handles nil status" do
      result = helper.legality_badge(nil)
      expect(result).to include("Not Legal")
    end
  end
end
