require "rails_helper"

RSpec.describe "Item List", type: :system do
  let(:collection) { create(:collection, name: "My Collection") }
  let(:card) { MTGJSON::Card.includes(:set, :identifiers).first }

  describe "viewing items" do
    context "with items in collection" do
      let!(:item) do
        create(:item,
          collection: collection,
          card_uuid: card.uuid,
          condition: :near_mint,
          finish: :nonfoil
        )
      end

      it "displays items list" do
        visit collection_items_path(collection)
        expect(page).to have_css("[data-testid='item-card']", count: 1)
      end

      it "shows card name" do
        visit collection_items_path(collection)
        expect(page).to have_content(card.name)
      end

      it "shows condition badge" do
        visit collection_items_path(collection)
        expect(page).to have_content("NM")
      end

      it "shows collection name in breadcrumb" do
        visit collection_items_path(collection)
        expect(page).to have_link("My Collection")
      end

      it "shows item count" do
        visit collection_items_path(collection)
        expect(page).to have_content("1 item")
      end
    end

    context "with foil items" do
      let!(:foil_item) do
        create(:item,
          collection: collection,
          card_uuid: card.uuid,
          finish: :traditional_foil
        )
      end

      it "displays foil badge" do
        visit collection_items_path(collection)
        expect(page).to have_content("Traditional foil")
      end
    end

    context "with signed items" do
      let!(:signed_item) do
        create(:item,
          collection: collection,
          card_uuid: card.uuid,
          signed: true
        )
      end

      it "displays signed badge" do
        visit collection_items_path(collection)
        expect(page).to have_content("Signed")
      end
    end

    context "with storage unit" do
      let(:storage_unit) { create(:storage_unit, collection: collection, name: "Box A") }
      let!(:item) do
        create(:item,
          collection: collection,
          card_uuid: card.uuid,
          storage_unit: storage_unit
        )
      end

      it "displays storage location" do
        visit collection_items_path(collection)
        expect(page).to have_content("Box A")
      end
    end

    context "with non-English items" do
      let!(:item) do
        create(:item,
          collection: collection,
          card_uuid: card.uuid,
          language: "ja"
        )
      end

      it "displays language indicator" do
        visit collection_items_path(collection)
        expect(page).to have_content("JA")
      end
    end
  end

  describe "empty collection" do
    it "shows empty state message" do
      visit collection_items_path(collection)
      expect(page).to have_content("No items in this collection")
    end

    it "shows search cards button" do
      visit collection_items_path(collection)
      expect(page).to have_link("Search for Cards")
    end
  end

  describe "navigation" do
    let!(:item) do
      create(:item, collection: collection, card_uuid: card.uuid)
    end

    it "navigates to item detail on click" do
      visit collection_items_path(collection)
      find("[data-testid='item-card']").click
      expect(page).to have_current_path(item_path(item))
    end

    it "navigates to add card" do
      visit collection_items_path(collection)
      click_link "Add Card"
      expect(page).to have_current_path(cards_path)
    end

    it "navigates back to collection" do
      visit collection_items_path(collection)
      click_link "My Collection"
      expect(page).to have_current_path(collection_path(collection))
    end
  end

  describe "pagination" do
    before do
      30.times { create(:item, collection: collection, card_uuid: card.uuid) }
    end

    it "shows first page" do
      visit collection_items_path(collection)
      expect(page).to have_css("[data-testid='item-card']", count: 24)
    end

    it "navigates to next page" do
      visit collection_items_path(collection)
      click_link "2"
      expect(page).to have_css("[data-testid='item-card']", count: 6)
    end
  end
end
