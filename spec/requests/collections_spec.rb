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
end
