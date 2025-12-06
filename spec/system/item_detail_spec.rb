require "rails_helper"

RSpec.describe "Item Detail and Edit", type: :system do
  let(:collection) { create(:collection, name: "My Collection") }
  let(:card) { MTGJSON::Card.includes(:set, :identifiers).first }
  let!(:item) do
    create(:item,
      collection: collection,
      card_uuid: card.uuid,
      condition: :near_mint,
      finish: :nonfoil,
      language: "en"
    )
  end

  describe "viewing item details" do
    before { visit item_path(item) }

    it "displays the card name" do
      expect(page).to have_content(card.name)
    end

    it "displays the condition" do
      expect(page).to have_content("Near mint (NM)")
    end

    it "displays the finish" do
      expect(page).to have_content("Nonfoil")
    end

    it "displays the language" do
      expect(page).to have_content("English")
    end

    it "displays the collection name" do
      expect(page).to have_link("My Collection")
    end

    it "shows edit button" do
      expect(page).to have_link("Edit Item")
    end

    it "shows delete button" do
      expect(page).to have_button("Delete")
    end

    it "shows back to items link" do
      expect(page).to have_link("Back to Items")
    end
  end

  describe "viewing item with special attributes" do
    let!(:special_item) do
      create(:item,
        collection: collection,
        card_uuid: card.uuid,
        signed: true,
        altered: true,
        misprint: true
      )
    end

    it "displays special attribute badges" do
      visit item_path(special_item)
      expect(page).to have_content("Signed")
      expect(page).to have_content("Altered")
      expect(page).to have_content("Misprint")
    end
  end

  describe "viewing item with acquisition info" do
    let!(:acquired_item) do
      create(:item,
        collection: collection,
        card_uuid: card.uuid,
        acquisition_date: Date.new(2024, 6, 15),
        acquisition_price: 25.50,
        notes: "Purchased at GP Vegas"
      )
    end

    it "displays acquisition date" do
      visit item_path(acquired_item)
      expect(page).to have_content("June 15, 2024")
    end

    it "displays acquisition price" do
      visit item_path(acquired_item)
      expect(page).to have_content("$25.50")
    end

    it "displays notes" do
      visit item_path(acquired_item)
      expect(page).to have_content("Purchased at GP Vegas")
    end
  end

  describe "viewing item with storage unit" do
    let(:storage_unit) { create(:storage_unit, collection: collection, name: "Deck Box Alpha") }
    let!(:stored_item) do
      create(:item,
        collection: collection,
        card_uuid: card.uuid,
        storage_unit: storage_unit
      )
    end

    it "displays storage unit name" do
      visit item_path(stored_item)
      expect(page).to have_content("Deck Box Alpha")
    end
  end

  describe "editing an item" do
    before { visit edit_item_path(item) }

    it "displays the edit form" do
      expect(page).to have_content("Edit Item")
      expect(page).to have_select("item[condition]")
    end

    it "shows current values" do
      expect(page).to have_select("item[condition]", selected: "Near mint (NM)")
    end

    it "updates the item" do
      select "Lightly played (LP)", from: "item[condition]"
      click_button "Save Changes"

      expect(page).to have_current_path(item_path(item))
      expect(page).to have_content("updated")
      expect(item.reload.condition).to eq("lightly_played")
    end

    it "updates multiple fields" do
      select "Moderately played (MP)", from: "item[condition]"
      select "Traditional Foil", from: "item[finish]"
      select "Japanese", from: "item[language]"
      find("label", text: "Signed").click

      click_button "Save Changes"

      # Wait for redirect and success message
      expect(page).to have_current_path(item_path(item))
      expect(page).to have_content("updated")

      item.reload
      expect(item.condition).to eq("moderately_played")
      expect(item.finish).to eq("traditional_foil")
      expect(item.language).to eq("ja")
      expect(item.signed).to be true
    end

    it "cancels and returns to item" do
      click_link "Cancel"
      expect(page).to have_current_path(item_path(item))
    end
  end

  describe "navigation" do
    it "navigates from item list to detail" do
      visit collection_items_path(collection)
      find("[data-testid='item-card']").click
      expect(page).to have_current_path(item_path(item))
    end

    it "navigates from detail to edit" do
      visit item_path(item)
      click_link "Edit Item"
      expect(page).to have_current_path(edit_item_path(item))
    end

    it "navigates back to items list" do
      visit item_path(item)
      click_link "Back to Items"
      expect(page).to have_current_path(collection_items_path(collection))
    end

    it "navigates to collection" do
      visit item_path(item)
      click_link "My Collection"
      expect(page).to have_current_path(collection_path(collection))
    end
  end
end
