require "rails_helper"

RSpec.describe "Delete Item", type: :system do
  before do
    driven_by(:selenium_headless)
  end

  let(:collection) { create(:collection, name: "My Collection") }
  let(:card) { MTGJSON::Card.first }
  let!(:item) { create(:item, collection: collection, card_uuid: card.uuid) }

  describe "deleting from item detail page" do
    before { visit item_path(item) }

    it "shows delete button" do
      expect(page).to have_button("Delete")
    end

    it "shows confirmation dialog with card name" do
      # The turbo_confirm attribute includes the card name
      delete_button = find("button", text: "Delete")
      form = delete_button.ancestor("form")
      expect(form["data-turbo-confirm"]).to include(card.name)
    end

    it "can cancel deletion" do
      dismiss_confirm do
        click_button "Delete"
      end

      expect(page).to have_current_path(item_path(item))
      expect(Item.exists?(item.id)).to be true
    end

    it "deletes item on confirm" do
      accept_confirm do
        click_button "Delete"
      end

      expect(page).to have_content("removed")
      expect(Item.exists?(item.id)).to be false
    end

    it "redirects to collection items" do
      accept_confirm do
        click_button "Delete"
      end

      expect(page).to have_current_path(collection_items_path(collection))
    end

    it "shows success message with card name" do
      accept_confirm do
        click_button "Delete"
      end

      expect(page).to have_content(card.name)
      expect(page).to have_content("removed")
    end
  end

  describe "deleting last item in collection" do
    it "shows empty state after deletion" do
      visit item_path(item)

      accept_confirm do
        click_button "Delete"
      end

      expect(page).to have_content("No items")
    end
  end

  describe "item count update" do
    let!(:item2) { create(:item, collection: collection, card_uuid: card.uuid) }

    it "updates item count after deletion" do
      visit item_path(item)

      expect(collection.items.count).to eq(2)

      accept_confirm do
        click_button "Delete"
      end

      expect(page).to have_content("1 item")
    end
  end

  describe "deleting item with storage unit" do
    let(:storage_unit) { create(:storage_unit, collection: collection, name: "Box A") }
    let!(:item) { create(:item, collection: collection, storage_unit: storage_unit, card_uuid: card.uuid) }

    it "deletes item but keeps storage unit" do
      visit item_path(item)

      accept_confirm do
        click_button "Delete"
      end

      # Wait for redirect and success message
      expect(page).to have_content("removed")
      expect(Item.exists?(item.id)).to be false
      expect(StorageUnit.exists?(storage_unit.id)).to be true
    end
  end
end
