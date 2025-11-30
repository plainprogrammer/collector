require "rails_helper"

RSpec.describe "Set Browser", type: :system do
  before do
    driven_by(:selenium_headless)
  end

  describe "viewing sets index" do
    it "displays list of sets" do
      visit sets_path

      expect(page).to have_selector("h1", text: "Sets")
      expect(page).to have_css("[data-testid='set-card']", minimum: 1)
    end

    it "shows set information" do
      visit sets_path

      within first("[data-testid='set-card']") do
        expect(page).to have_css("[data-testid='set-code']")
        expect(page).to have_css("[data-testid='set-name']")
        expect(page).to have_css("[data-testid='set-release-date']")
      end
    end

    it "filters sets by type via auto-submit" do
      visit sets_path

      select "Expansion", from: "type"
      # Auto-submits on change via Turbo

      expect(page).to have_current_path(/type=expansion/)
    end

    it "clears filter when selecting All Types" do
      visit sets_path(type: "expansion")

      select "All Types", from: "type"

      # After selecting All Types, the type param is empty so all sets are shown
      expect(page).to have_current_path(/type=$|sets$/)
    end

    it "paginates sets" do
      visit sets_path

      expect(page).to have_css("nav[aria-label='Pagination']")
    end

    it "navigates to next page" do
      visit sets_path

      # Find and click a pagination link if available
      if page.has_link?("2")
        click_link "2"
        expect(page).to have_current_path(/page=2/)
      end
    end
  end

  describe "viewing set details" do
    # Find a set that has cards (some sets like memorabilia may have no cards)
    let(:set) { MTGJSON::Set.released.joins(:cards).order(releaseDate: :desc).first }

    it "displays set name" do
      visit set_path(set.code)

      expect(page).to have_selector("h1", text: set.name)
    end

    it "displays set code" do
      visit set_path(set.code)

      expect(page).to have_content(set.code)
    end

    it "displays release date" do
      visit set_path(set.code)

      expect(page).to have_content(set.releaseDate)
    end

    it "lists cards in the set" do
      visit set_path(set.code)

      expect(page).to have_css("[data-testid='card-row']", minimum: 1)
    end

    it "navigates back to sets index" do
      visit set_path(set.code)

      click_link "Back to Sets"

      expect(page).to have_current_path(sets_path)
    end

    it "displays card name with link" do
      visit set_path(set.code)

      within first("[data-testid='card-row']") do
        expect(page).to have_css("a")
      end
    end

    it "displays card rarity" do
      visit set_path(set.code)

      within first("[data-testid='card-row']") do
        # Rarity badge should be present
        expect(page).to have_css("span", text: /Common|Uncommon|Rare|Mythic|Special/i)
      end
    end
  end

  describe "navigation" do
    before do
      # Resize window to show desktop navigation (sm: breakpoint is 640px)
      page.driver.browser.manage.window.resize_to(1024, 768)
    end

    it "has Sets link in main navigation" do
      visit root_path

      expect(page).to have_link("Sets", href: sets_path)
    end

    it "highlights Sets in navigation when on sets page" do
      visit sets_path

      expect(page).to have_css("a.text-indigo-600", text: "Sets")
    end

    it "navigates from collections to sets" do
      visit collections_path

      click_link "Sets"

      expect(page).to have_current_path(sets_path)
    end
  end

  describe "responsive design" do
    it "displays properly on mobile viewport" do
      page.driver.browser.manage.window.resize_to(375, 667)

      visit sets_path

      expect(page).to have_css("[data-testid='set-card']", minimum: 1)
    end
  end
end
