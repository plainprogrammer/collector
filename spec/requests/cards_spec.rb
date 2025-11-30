require "rails_helper"

RSpec.describe "Cards", type: :request do
  describe "GET /cards" do
    context "without search params" do
      it "returns successful response" do
        get cards_path
        expect(response).to have_http_status(:ok)
      end

      it "displays search prompt" do
        get cards_path
        expect(response.body).to include("Search for cards")
      end

      it "does not display card results" do
        get cards_path
        expect(response.body).not_to include("cards found")
      end
    end

    context "with name search" do
      it "returns successful response" do
        get cards_path, params: { name: "Lightning Bolt" }
        expect(response).to have_http_status(:ok)
      end

      it "displays matching cards" do
        get cards_path, params: { name: "Lightning Bolt" }
        expect(response.body).to include("Lightning Bolt")
      end

      it "displays result count" do
        get cards_path, params: { name: "Lightning Bolt" }
        expect(response.body).to include("cards found")
      end
    end

    context "with set code search" do
      let(:set) { MTGJSON::Set.released.joins(:cards).first }

      it "returns successful response" do
        get cards_path, params: { set_code: set.code }
        expect(response).to have_http_status(:ok)
      end

      it "displays cards from the set" do
        # Get the first card that would appear on the first page (ordered by name)
        card = set.cards.order(:name).first
        get cards_path, params: { set_code: set.code }
        expect(response.body).to include(card.name)
      end
    end

    context "with combined name and set code search" do
      let(:set) { MTGJSON::Set.released.joins(:cards).first }
      let(:card) { set.cards.first }

      it "returns successful response" do
        get cards_path, params: { name: card.name, set_code: set.code }
        expect(response).to have_http_status(:ok)
      end
    end

    context "with no results" do
      it "displays no results message" do
        get cards_path, params: { name: "xyznonexistentcardname" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("No cards found")
      end
    end

    context "with pagination" do
      it "paginates results" do
        # Search for common term to get many results
        get cards_path, params: { name: "Goblin", page: 2 }
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /cards/:uuid" do
    context "when card exists" do
      let(:card) { MTGJSON::Card.first }

      it "returns successful response" do
        get card_path(card.uuid)
        expect(response).to have_http_status(:ok)
      end

      it "displays card name" do
        get card_path(card.uuid)
        expect(response.body).to include(card.name)
      end
    end

    context "when card does not exist" do
      it "redirects with error message" do
        get card_path("invalid-uuid-123")
        expect(response).to redirect_to(cards_path)
      end

      it "sets flash alert message" do
        get card_path("invalid-uuid-123")
        follow_redirect!
        expect(response.body).to include("Card not found")
      end
    end
  end
end
