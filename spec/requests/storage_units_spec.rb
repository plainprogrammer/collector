require "rails_helper"

RSpec.describe "StorageUnits", type: :request do
  let(:collection) { Collection.create!(name: "Test Collection") }

  describe "GET /collections/:collection_id/storage_units/new" do
    it "returns a successful response" do
      get new_collection_storage_unit_path(collection)
      expect(response).to have_http_status(:success)
    end

    it "displays the new storage unit form" do
      get new_collection_storage_unit_path(collection)
      expect(response.body).to include("Add Storage Unit")
    end
  end

  describe "POST /collections/:collection_id/storage_units" do
    context "with valid parameters" do
      let(:valid_params) do
        { storage_unit: { name: "Card Box", storage_unit_type: "box" } }
      end

      it "creates a new storage unit" do
        expect {
          post collection_storage_units_path(collection), params: valid_params
        }.to change(StorageUnit, :count).by(1)
      end

      it "associates the storage unit with the collection" do
        post collection_storage_units_path(collection), params: valid_params
        expect(StorageUnit.last.collection).to eq(collection)
      end

      it "redirects to the collection" do
        post collection_storage_units_path(collection), params: valid_params
        expect(response).to redirect_to(collection)
      end
    end

    context "with invalid parameters" do
      it "does not create a new storage unit" do
        expect {
          post collection_storage_units_path(collection), params: { storage_unit: { name: "" } }
        }.not_to change(StorageUnit, :count)
      end

      it "returns an unprocessable entity status" do
        post collection_storage_units_path(collection), params: { storage_unit: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with parent storage unit" do
      let!(:parent) { collection.storage_units.create!(name: "Main Box", storage_unit_type: "box") }

      it "creates a nested storage unit" do
        expect {
          post collection_storage_units_path(collection), params: {
            storage_unit: { name: "Deck inside Box", storage_unit_type: "deck", parent_id: parent.id }
          }
        }.to change(StorageUnit, :count).by(1)

        expect(StorageUnit.last.parent).to eq(parent)
      end
    end
  end

  describe "GET /storage_units/:id/edit" do
    let(:storage_unit) { collection.storage_units.create!(name: "Card Box", storage_unit_type: "box") }

    it "returns a successful response" do
      get edit_storage_unit_path(storage_unit)
      expect(response).to have_http_status(:success)
    end

    it "displays the edit form" do
      get edit_storage_unit_path(storage_unit)
      expect(response.body).to include("Edit Storage Unit")
    end
  end

  describe "PATCH /storage_units/:id" do
    let(:storage_unit) { collection.storage_units.create!(name: "Original Name", storage_unit_type: "box") }

    context "with valid parameters" do
      it "updates the storage unit" do
        patch storage_unit_path(storage_unit), params: { storage_unit: { name: "Updated Name" } }
        expect(storage_unit.reload.name).to eq("Updated Name")
      end

      it "redirects to the collection" do
        patch storage_unit_path(storage_unit), params: { storage_unit: { name: "Updated Name" } }
        expect(response).to redirect_to(collection)
      end
    end

    context "with invalid parameters" do
      it "does not update the storage unit" do
        patch storage_unit_path(storage_unit), params: { storage_unit: { name: "" } }
        expect(storage_unit.reload.name).to eq("Original Name")
      end

      it "returns an unprocessable entity status" do
        patch storage_unit_path(storage_unit), params: { storage_unit: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /storage_units/:id" do
    let!(:storage_unit) { collection.storage_units.create!(name: "Card Box", storage_unit_type: "box") }

    it "destroys the storage unit" do
      expect {
        delete storage_unit_path(storage_unit)
      }.to change(StorageUnit, :count).by(-1)
    end

    it "redirects to the collection" do
      delete storage_unit_path(storage_unit)
      expect(response).to redirect_to(collection)
    end
  end

  describe "storage unit types" do
    it "can create all storage unit types" do
      types = %w[box binder deck deck_box portfolio toploader_case loose other]

      types.each do |type|
        expect {
          post collection_storage_units_path(collection), params: {
            storage_unit: { name: "#{type.humanize} Unit", storage_unit_type: type }
          }
        }.to change(StorageUnit, :count).by(1)
      end
    end
  end
end
