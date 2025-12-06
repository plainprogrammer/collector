require "rails_helper"

RSpec.describe "Collection Management", type: :system do
  describe "viewing collections" do
    let!(:collection) { Collection.create!(name: "My MTG Cards", description: "All my Magic cards") }

    it "allows clicking a collection from the index to view its details" do
      visit collections_path

      # Click on the collection card using its aria-label
      find("a[aria-label='View My MTG Cards collection']").click

      # Should navigate to the collection show page
      expect(page).to have_current_path(collection_path(collection))
      expect(page).to have_content("My MTG Cards")
      expect(page).to have_content("All my Magic cards")
      expect(page).to have_content("Storage Units")
    end

    it "displays collection cards on the index page" do
      visit collections_path

      expect(page).to have_content("My MTG Cards")
      expect(page).to have_content("0 cards")
      expect(page).to have_content("0 storage units")
    end
  end

  describe "creating a new collection" do
    it "allows creating a collection from the index page" do
      visit collections_path

      # Click the "New Collection" link in the empty state section
      within("section[aria-labelledby='collections-heading']") do
        first(:link, "New Collection").click
      end

      expect(page).to have_content("Create New Collection")

      fill_in "Name", with: "My Commander Decks"
      fill_in "Description", with: "All my EDH decks"

      click_button "Create Collection"

      # Wait for the redirect and check the page content
      expect(page).to have_content("My Commander Decks")
      expect(page).to have_content("Collection was successfully created")
    end

    it "shows validation errors when name is blank" do
      visit new_collection_path

      # Clear the name field and submit
      fill_in "Name", with: ""
      click_button "Create Collection"

      expect(page).to have_content("Name can't be blank")
    end

    it "allows creating a collection and seeing it on the index" do
      visit collections_path

      # Click the "New Collection" link in the main section
      within("section[aria-labelledby='collections-heading']") do
        first(:link, "New Collection").click
      end

      fill_in "Name", with: "Trade Binder"
      click_button "Create Collection"

      # Navigate back to index using the nav link
      click_link("Collections", match: :first)

      expect(page).to have_content("Trade Binder")
    end
  end

  describe "editing a collection" do
    let!(:collection) { Collection.create!(name: "Original Name", description: "Original description") }

    it "allows editing a collection" do
      visit collection_path(collection)

      click_link "Edit"

      expect(page).to have_content("Edit Collection")

      fill_in "Name", with: "Updated Name"
      click_button "Update Collection"

      expect(page).to have_current_path(collection_path(collection))
      expect(page).to have_content("Updated Name")
      expect(page).to have_content("Collection was successfully updated")
    end
  end

  describe "deleting a collection" do
    let!(:collection) { Collection.create!(name: "To Delete") }

    it "allows deleting a collection" do
      visit collection_path(collection)

      accept_confirm do
        click_button "Delete"
      end

      expect(page).to have_current_path(collections_path)
      expect(page).to have_content("Collection was successfully deleted")
      expect(page).not_to have_content("To Delete")
    end
  end

  describe "managing storage units" do
    let!(:collection) { Collection.create!(name: "My Collection") }

    it "allows adding a storage unit to a collection" do
      visit collection_path(collection)

      click_link "Add Storage"

      expect(page).to have_content("Add Storage Unit")

      select "Box", from: "Type"
      fill_in "Name", with: "Long Box #1"
      fill_in "Description", with: "Comics and oversized cards"
      fill_in "Location", with: "Closet shelf"

      click_button "Add Storage Unit"

      expect(page).to have_content("Long Box #1")
      expect(page).to have_content("Box")
      expect(page).to have_content("Storage unit was successfully created")
    end

    it "allows creating nested storage units" do
      box = collection.storage_units.create!(name: "Main Box", storage_unit_type: "box")

      visit collection_path(collection)

      # Expand the box to see nested options - use first to get parent's button only
      within("article", text: "Main Box") do
        first("button[data-action='expandable#toggle']").click
      end

      click_link "Add nested storage"

      select "Deck", from: "Type"
      fill_in "Name", with: "Mono Red Aggro"

      click_button "Add Storage Unit"

      # Wait for page to reload and expand the parent to see nested storage unit
      # Use first button since nested articles also have toggle buttons
      expect(page).to have_content("Storage unit was successfully created")

      within("article", text: "Main Box") do
        first("button[data-action='expandable#toggle']").click
      end

      expect(page).to have_content("Mono Red Aggro")
    end

    it "allows editing a storage unit" do
      storage_unit = collection.storage_units.create!(name: "Old Name", storage_unit_type: "binder")

      visit collection_path(collection)

      within("article", text: "Old Name") do
        find("a[aria-label='Edit Old Name']").click
      end

      fill_in "Name", with: "New Binder Name"
      click_button "Update"

      expect(page).to have_content("New Binder Name")
      expect(page).to have_content("Storage unit was successfully updated")
    end

    it "allows deleting a storage unit" do
      collection.storage_units.create!(name: "To Remove", storage_unit_type: "deck")

      visit collection_path(collection)

      within("article", text: "To Remove") do
        accept_confirm do
          find("button[aria-label='Delete To Remove']").click
        end
      end

      expect(page).not_to have_content("To Remove")
      expect(page).to have_content("Storage unit was successfully deleted")
    end
  end
end
