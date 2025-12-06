require "rails_helper"

RSpec.describe "Items", type: :request do
  let(:collection) { create(:collection) }
  let(:card) { MTGJSON::Card.first }

  describe "GET /collections/:collection_id/items" do
    context "with items" do
      before do
        5.times { create(:item, collection: collection, card_uuid: card.uuid) }
      end

      it "returns successful response" do
        get collection_items_path(collection)
        expect(response).to have_http_status(:ok)
      end

      it "displays item count" do
        get collection_items_path(collection)
        expect(response.body).to include("5 items")
      end

      it "displays card names" do
        get collection_items_path(collection)
        expect(response.body).to include(card.name)
      end
    end

    context "with empty collection" do
      it "shows empty state" do
        get collection_items_path(collection)
        expect(response.body).to include("No items")
      end

      it "shows link to add cards" do
        get collection_items_path(collection)
        expect(response.body).to include("Add Card")
      end
    end

    context "with special items" do
      it "shows foil badge" do
        create(:item, collection: collection, card_uuid: card.uuid, finish: :traditional_foil)
        get collection_items_path(collection)
        expect(response.body).to include("Traditional")
      end

      it "shows signed badge" do
        create(:item, collection: collection, card_uuid: card.uuid, signed: true)
        get collection_items_path(collection)
        expect(response.body).to include("Signed")
      end

      it "shows language badge for non-English items" do
        create(:item, collection: collection, card_uuid: card.uuid, language: "ja")
        get collection_items_path(collection)
        expect(response.body).to include("JA")
      end
    end

    context "with storage unit" do
      it "shows storage unit name" do
        storage_unit = create(:storage_unit, collection: collection, name: "Box A")
        create(:item, collection: collection, card_uuid: card.uuid, storage_unit: storage_unit)
        get collection_items_path(collection)
        expect(response.body).to include("Box A")
      end
    end
  end

  describe "GET /collections/:collection_id/items/new" do
    context "with valid card_uuid" do
      it "returns successful response" do
        get new_collection_item_path(collection), params: { card_uuid: card.uuid }
        expect(response).to have_http_status(:ok)
      end

      it "displays the card name" do
        get new_collection_item_path(collection), params: { card_uuid: card.uuid }
        expect(response.body).to include(card.name)
      end

      it "displays the collection name" do
        get new_collection_item_path(collection), params: { card_uuid: card.uuid }
        expect(response.body).to include(collection.name)
      end

      it "shows condition dropdown with default" do
        get new_collection_item_path(collection), params: { card_uuid: card.uuid }
        expect(response.body).to include("Near mint (NM)")
      end

      it "shows storage unit dropdown" do
        storage_unit = create(:storage_unit, collection: collection, name: "Box A")
        get new_collection_item_path(collection), params: { card_uuid: card.uuid }
        expect(response.body).to include("Box A")
      end
    end

    context "with invalid card_uuid" do
      it "redirects to cards path" do
        get new_collection_item_path(collection), params: { card_uuid: "invalid-uuid" }
        expect(response).to redirect_to(cards_path)
      end

      it "shows alert message" do
        get new_collection_item_path(collection), params: { card_uuid: "invalid-uuid" }
        expect(flash[:alert]).to eq("Card not found")
      end
    end
  end

  describe "POST /collections/:collection_id/items" do
    let(:valid_params) do
      {
        card_uuid: card.uuid,
        item: {
          condition: "near_mint",
          finish: "nonfoil",
          language: "en"
        }
      }
    end

    context "with valid parameters" do
      it "creates a new item" do
        expect {
          post collection_items_path(collection), params: valid_params
        }.to change(Item, :count).by(1)
      end

      it "sets the card_uuid from the params" do
        post collection_items_path(collection), params: valid_params
        expect(Item.last.card_uuid).to eq(card.uuid)
      end

      it "redirects to collection items" do
        post collection_items_path(collection), params: valid_params
        expect(response).to redirect_to(collection_items_path(collection))
      end

      it "shows success message" do
        post collection_items_path(collection), params: valid_params
        follow_redirect!
        expect(response.body).to include("added to")
      end
    end

    context "with storage unit" do
      let(:storage_unit) { create(:storage_unit, collection: collection) }

      it "assigns item to storage unit" do
        params = valid_params.deep_merge(item: { storage_unit_id: storage_unit.id })
        post collection_items_path(collection), params: params
        expect(Item.last.storage_unit).to eq(storage_unit)
      end
    end

    context "with all optional fields" do
      let(:storage_unit) { create(:storage_unit, collection: collection) }

      it "saves all attributes" do
        params = {
          card_uuid: card.uuid,
          item: {
            storage_unit_id: storage_unit.id,
            condition: "lightly_played",
            finish: "traditional_foil",
            language: "ja",
            signed: true,
            altered: false,
            misprint: true,
            acquisition_date: "2024-01-15",
            acquisition_price: "25.50",
            notes: "From GP Vegas"
          }
        }

        post collection_items_path(collection), params: params

        item = Item.last
        expect(item.condition).to eq("lightly_played")
        expect(item.finish).to eq("traditional_foil")
        expect(item.language).to eq("ja")
        expect(item.signed).to be true
        expect(item.misprint).to be true
        expect(item.acquisition_date).to eq(Date.new(2024, 1, 15))
        expect(item.acquisition_price).to eq(25.50)
        expect(item.notes).to eq("From GP Vegas")
      end
    end

    context "with invalid parameters" do
      it "does not create item with invalid language" do
        params = valid_params.deep_merge(item: { language: "xxx" })
        expect {
          post collection_items_path(collection), params: params
        }.not_to change(Item, :count)
      end

      it "re-renders form with errors" do
        params = valid_params.deep_merge(item: { language: "xxx" })
        post collection_items_path(collection), params: params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /items/:id" do
    let!(:item) { create(:item, collection: collection, card_uuid: card.uuid) }

    it "returns successful response" do
      get item_path(item)
      expect(response).to have_http_status(:ok)
    end

    it "displays the card name" do
      get item_path(item)
      expect(response.body).to include(card.name)
    end

    it "displays the condition" do
      get item_path(item)
      expect(response.body).to include("Near mint")
    end

    it "shows edit and delete buttons" do
      get item_path(item)
      expect(response.body).to include("Edit Item")
      expect(response.body).to include("Delete")
    end
  end

  describe "GET /items/:id/edit" do
    let!(:item) { create(:item, collection: collection, card_uuid: card.uuid) }

    it "returns successful response" do
      get edit_item_path(item)
      expect(response).to have_http_status(:ok)
    end

    it "displays the card name" do
      get edit_item_path(item)
      expect(response.body).to include(card.name)
    end

    it "displays current condition" do
      get edit_item_path(item)
      expect(response.body).to include("near_mint")
    end
  end

  describe "PATCH /items/:id" do
    let!(:item) { create(:item, collection: collection, card_uuid: card.uuid, condition: :near_mint) }

    context "with valid parameters" do
      it "updates the item" do
        patch item_path(item), params: { item: { condition: "lightly_played" } }
        expect(item.reload.condition).to eq("lightly_played")
      end

      it "redirects to item show page" do
        patch item_path(item), params: { item: { condition: "lightly_played" } }
        expect(response).to redirect_to(item_path(item))
      end

      it "shows success message" do
        patch item_path(item), params: { item: { condition: "lightly_played" } }
        expect(flash[:notice]).to include("updated")
      end
    end

    context "with all editable fields" do
      let(:storage_unit) { create(:storage_unit, collection: collection) }

      it "updates all attributes" do
        patch item_path(item), params: {
          item: {
            storage_unit_id: storage_unit.id,
            condition: "moderately_played",
            finish: "traditional_foil",
            language: "de",
            signed: true,
            altered: true,
            misprint: false,
            grading_service: "PSA",
            grading_score: "9.5",
            acquisition_date: "2024-03-15",
            acquisition_price: "150.00",
            notes: "Trade at GP"
          }
        }

        item.reload
        expect(item.storage_unit).to eq(storage_unit)
        expect(item.condition).to eq("moderately_played")
        expect(item.finish).to eq("traditional_foil")
        expect(item.language).to eq("de")
        expect(item.signed).to be true
        expect(item.altered).to be true
        expect(item.grading_service).to eq("PSA")
        expect(item.grading_score.to_f).to eq(9.5)
      end
    end

    context "with invalid parameters" do
      it "does not update with invalid language" do
        patch item_path(item), params: { item: { language: "invalid" } }
        expect(item.reload.language).to eq("en")
      end

      it "re-renders edit form" do
        patch item_path(item), params: { item: { language: "invalid" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /items/:id/move" do
    let!(:item) { create(:item, collection: collection, card_uuid: card.uuid) }
    let!(:other_collection) { create(:collection, name: "Other Collection") }

    it "returns successful response" do
      get move_item_path(item)
      expect(response).to have_http_status(:ok)
    end

    it "displays the move form" do
      get move_item_path(item)
      expect(response.body).to include("Move Item")
      expect(response.body).to include("New Location")
    end

    it "lists available collections" do
      get move_item_path(item)
      expect(response.body).to include(collection.name)
      expect(response.body).to include("Other Collection")
    end
  end

  describe "PATCH /items/:id/relocate" do
    let!(:item) { create(:item, collection: collection, card_uuid: card.uuid) }
    let!(:other_collection) { create(:collection, name: "Other Collection") }
    let!(:other_storage) { create(:storage_unit, collection: other_collection, name: "New Box") }

    context "moving to same collection" do
      let!(:storage_unit) { create(:storage_unit, collection: collection, name: "Box A") }

      it "updates storage unit" do
        patch relocate_item_path(item), params: { item: { collection_id: collection.id, storage_unit_id: storage_unit.id } }
        expect(item.reload.storage_unit).to eq(storage_unit)
      end
    end

    context "moving to different collection" do
      it "moves item to new collection" do
        patch relocate_item_path(item), params: { item: { collection_id: other_collection.id } }
        expect(item.reload.collection).to eq(other_collection)
      end

      it "clears storage unit when moving collection" do
        item.update!(storage_unit: create(:storage_unit, collection: collection))
        patch relocate_item_path(item), params: { item: { collection_id: other_collection.id } }
        expect(item.reload.storage_unit).to be_nil
      end

      it "can assign storage unit from new collection" do
        patch relocate_item_path(item), params: { item: { collection_id: other_collection.id, storage_unit_id: other_storage.id } }
        expect(item.reload.storage_unit).to eq(other_storage)
      end

      it "redirects to item with success message" do
        patch relocate_item_path(item), params: { item: { collection_id: other_collection.id } }
        expect(response).to redirect_to(item_path(item))
        expect(flash[:notice]).to include("moved")
      end
    end
  end
end
