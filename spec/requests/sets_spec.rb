require "rails_helper"

RSpec.describe "Sets", type: :request do
  describe "GET /sets" do
    it "returns successful response" do
      get sets_path
      expect(response).to have_http_status(:ok)
    end

    it "displays sets ordered by release date descending" do
      get sets_path

      # Get actual sets in expected order
      first_set = MTGJSON::Set.released.order(releaseDate: :desc).first
      expect(response.body).to include(first_set.name)
    end

    it "displays set type filter dropdown" do
      get sets_path
      expect(response.body).to include("All Types")
    end

    context "with type filter" do
      it "filters sets by type" do
        get sets_path, params: { type: "expansion" }
        expect(response).to have_http_status(:ok)
      end

      it "preserves selected type in filter" do
        get sets_path, params: { type: "expansion" }
        expect(response.body).to include('selected')
      end
    end

    context "with pagination" do
      it "paginates results" do
        get sets_path, params: { page: 2 }
        expect(response).to have_http_status(:ok)
      end

      it "shows pagination controls" do
        get sets_path
        expect(response.body).to include("pagy")
      end
    end

    context "when no sets match filter" do
      it "shows empty state message" do
        get sets_path, params: { type: "nonexistent_type" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("No sets")
      end
    end
  end

  describe "GET /sets/:code" do
    context "when set exists" do
      let(:set) { MTGJSON::Set.released.first }

      it "returns successful response" do
        get set_path(set.code)
        expect(response).to have_http_status(:ok)
      end

      it "displays set name" do
        get set_path(set.code)
        expect(response.body).to include(set.name)
      end

      it "displays set code" do
        get set_path(set.code)
        expect(response.body).to include(set.code)
      end

      it "displays release date" do
        get set_path(set.code)
        expect(response.body).to include(set.releaseDate)
      end

      it "displays cards in the set" do
        get set_path(set.code)
        expect(response.body).to include("Cards in this set")
      end

      it "shows back to sets link" do
        get set_path(set.code)
        expect(response.body).to include("Back to Sets")
      end
    end

    context "when set does not exist" do
      it "redirects with error message" do
        get set_path("INVALID")
        expect(response).to redirect_to(sets_path)
      end

      it "sets flash alert message" do
        get set_path("INVALID")
        follow_redirect!
        expect(response.body).to include("Set not found")
      end
    end

    context "with pagination" do
      let(:set) { MTGJSON::Set.released.first }

      it "paginates cards" do
        get set_path(set.code), params: { page: 1 }
        expect(response).to have_http_status(:ok)
      end
    end
  end
end
