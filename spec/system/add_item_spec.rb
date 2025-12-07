require "rails_helper"

RSpec.describe "Add Item to Collection", type: :system do
  let!(:collection) { create(:collection, name: "My Collection") }
  let(:card) { MTGJSON::Card.includes(:set, :identifiers).first }

  describe "from card detail page" do
    before { visit card_path(card.uuid) }

    it "displays add to collection section" do
      expect(page).to have_css("[data-testid='add-to-collection']")
    end

    it "shows collection dropdown" do
      within("[data-testid='add-to-collection']") do
        expect(page).to have_select("collection_id")
      end
    end

    it "lists available collections" do
      within("[data-testid='add-to-collection']") do
        expect(page).to have_content("My Collection")
      end
    end

    context "when no collections exist" do
      before do
        Collection.destroy_all
        visit card_path(card.uuid)
      end

      it "shows create collection prompt" do
        within("[data-testid='add-to-collection']") do
          expect(page).to have_content("don't have any collections")
          expect(page).to have_link("Create a Collection")
        end
      end
    end
  end

  describe "adding item form" do
    before do
      visit new_collection_item_path(collection, card_uuid: card.uuid)
    end

    it "displays card preview" do
      expect(page).to have_content(card.name)
      expect(page).to have_content(card.type)
    end

    it "has condition dropdown" do
      expect(page).to have_select("item[condition]")
    end

    it "has finish dropdown" do
      expect(page).to have_select("item[finish]")
    end

    it "has language dropdown" do
      expect(page).to have_select("item[language]")
    end

    it "has special attributes checkboxes" do
      expect(page).to have_field("item[signed]", type: "checkbox")
      expect(page).to have_field("item[altered]", type: "checkbox")
      expect(page).to have_field("item[misprint]", type: "checkbox")
    end

    it "has acquisition fields" do
      expect(page).to have_field("item[acquisition_date]")
      expect(page).to have_field("item[acquisition_price]")
      expect(page).to have_field("item[notes]")
    end
  end

  describe "creating an item with minimum required fields" do
    before do
      visit new_collection_item_path(collection, card_uuid: card.uuid)
    end

    it "creates item with defaults and redirects" do
      initial_count = Item.count
      click_button "Add to Collection"

      expect(page).to have_current_path(collection_items_path(collection))
      expect(page).to have_content("added to")
      expect(Item.count).to eq(initial_count + 1)
    end
  end

  describe "creating item with all fields" do
    let!(:storage_unit) { create(:storage_unit, collection: collection, name: "Deck Box 1") }

    before do
      visit new_collection_item_path(collection, card_uuid: card.uuid)
    end

    it "saves all attributes" do
      select "Deck Box 1", from: "item[storage_unit_id]"
      select "Lightly played (LP)", from: "item[condition]"
      select "Traditional Foil", from: "item[finish]"
      select "Japanese", from: "item[language]"
      find("label", text: "Signed").click
      find("label", text: "Misprint").click
      fill_in "item[acquisition_date]", with: "2024-06-15"
      fill_in "item[acquisition_price]", with: "50.00"
      fill_in "item[notes]", with: "Signed at GP Vegas"

      click_button "Add to Collection"

      # Wait for redirect and flash message
      expect(page).to have_current_path(collection_items_path(collection))
      expect(page).to have_content("added to")

      item = Item.last
      expect(item.storage_unit).to eq(storage_unit)
      expect(item.condition).to eq("lightly_played")
      expect(item.finish).to eq("traditional_foil")
      expect(item.language).to eq("ja")
      expect(item.signed).to be true
      expect(item.misprint).to be true
      expect(item.acquisition_price.to_f).to eq(50.0)
      expect(item.notes).to eq("Signed at GP Vegas")
    end
  end

  describe "cancel button" do
    it "returns to card detail page" do
      visit new_collection_item_path(collection, card_uuid: card.uuid)
      click_link "Cancel"
      expect(page).to have_current_path(card_path(card.uuid))
    end
  end

  describe "navigation to add item form" do
    it "navigates from card page to add item form" do
      visit card_path(card.uuid)

      within("[data-testid='add-to-collection']") do
        select "My Collection", from: "collection_id"
        click_button "Add to Collection"
      end

      expect(page).to have_current_path(new_collection_item_path(collection, card_uuid: card.uuid))
      expect(page).to have_content(card.name)
    end
  end
end
