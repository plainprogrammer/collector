require "rails_helper"

RSpec.describe "Collections", type: :request do
  describe "GET /collections" do
    it "returns a successful response" do
      get collections_path
      expect(response).to have_http_status(:success)
    end

    it "displays the collections index page" do
      Collection.create!(name: "Test Collection")
      get collections_path
      expect(response.body).to include("Test Collection")
    end
  end

  describe "GET /collections/new" do
    it "returns a successful response" do
      get new_collection_path
      expect(response).to have_http_status(:success)
    end

    it "displays the new collection form" do
      get new_collection_path
      expect(response.body).to include("Create New Collection")
    end
  end

  describe "POST /collections" do
    context "with valid parameters" do
      it "creates a new collection" do
        expect {
          post collections_path, params: { collection: { name: "My Collection", description: "A test collection" } }
        }.to change(Collection, :count).by(1)
      end

      it "redirects to the created collection" do
        post collections_path, params: { collection: { name: "My Collection" } }
        expect(response).to redirect_to(Collection.last)
      end
    end

    context "with invalid parameters" do
      it "does not create a new collection" do
        expect {
          post collections_path, params: { collection: { name: "" } }
        }.not_to change(Collection, :count)
      end

      it "returns an unprocessable entity status" do
        post collections_path, params: { collection: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /collections/:id" do
    let(:collection) { Collection.create!(name: "Test Collection") }

    it "returns a successful response" do
      get collection_path(collection)
      expect(response).to have_http_status(:success)
    end

    it "displays the collection details" do
      get collection_path(collection)
      expect(response.body).to include(collection.name)
    end
  end

  describe "GET /collections/:id/edit" do
    let(:collection) { Collection.create!(name: "Test Collection") }

    it "returns a successful response" do
      get edit_collection_path(collection)
      expect(response).to have_http_status(:success)
    end

    it "displays the edit form" do
      get edit_collection_path(collection)
      expect(response.body).to include("Edit Collection")
    end
  end

  describe "PATCH /collections/:id" do
    let(:collection) { Collection.create!(name: "Original Name") }

    context "with valid parameters" do
      it "updates the collection" do
        patch collection_path(collection), params: { collection: { name: "Updated Name" } }
        expect(collection.reload.name).to eq("Updated Name")
      end

      it "redirects to the collection" do
        patch collection_path(collection), params: { collection: { name: "Updated Name" } }
        expect(response).to redirect_to(collection)
      end
    end

    context "with invalid parameters" do
      it "does not update the collection" do
        patch collection_path(collection), params: { collection: { name: "" } }
        expect(collection.reload.name).to eq("Original Name")
      end

      it "returns an unprocessable entity status" do
        patch collection_path(collection), params: { collection: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /collections/:id" do
    let!(:collection) { Collection.create!(name: "Test Collection") }

    it "destroys the collection" do
      expect {
        delete collection_path(collection)
      }.to change(Collection, :count).by(-1)
    end

    it "redirects to the collections index" do
      delete collection_path(collection)
      expect(response).to redirect_to(collections_path)
    end
  end

  describe "root path" do
    it "redirects to collections index" do
      get root_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("My Collections")
    end
  end

  describe "GET /collections/:id/statistics", :mtgjson do
    let(:collection) { create(:collection, name: "Test Collection") }
    let(:card) { MTGJSON::Card.first }

    context "with items" do
      before do
        create_list(:item, 5, collection: collection, card_uuid: card.uuid, condition: :near_mint)
        create_list(:item, 3, collection: collection, card_uuid: card.uuid, condition: :lightly_played, finish: :traditional_foil)
      end

      it "returns successful response" do
        get statistics_collection_path(collection)
        expect(response).to have_http_status(:ok)
      end

      it "displays total count" do
        get statistics_collection_path(collection)
        expect(response.body).to include("8")
      end

      it "displays unique count" do
        get statistics_collection_path(collection)
        expect(response.body).to include("Unique Cards")
      end

      it "displays condition breakdown" do
        get statistics_collection_path(collection)
        expect(response.body).to include("Condition")
        expect(response.body).to include("Near mint")
      end

      it "displays foil percentage" do
        get statistics_collection_path(collection)
        expect(response.body).to include("37.5%")
      end
    end

    context "empty collection" do
      it "shows empty state" do
        get statistics_collection_path(collection)
        expect(response.body).to include("No items")
      end
    end

    it "displays back link to collection" do
      get statistics_collection_path(collection)
      expect(response.body).to include("Back to")
      expect(response.body).to include(collection.name)
    end
  end

  describe "collection show page tabs" do
    let(:collection) { create(:collection, name: "Test Collection") }

    it "displays tab navigation" do
      get collection_path(collection)
      expect(response.body).to include("Items")
      expect(response.body).to include("Storage Units")
      expect(response.body).to include("Loose Items")
      expect(response.body).to include("Statistics")
    end

    it "highlights storage tab by default" do
      get collection_path(collection)
      expect(response.body).to include("Storage Units")
    end
  end
end
