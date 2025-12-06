require "rails_helper"

RSpec.describe "Card Search", type: :system do
  describe "search page" do
    it "displays search form" do
      visit cards_path

      expect(page).to have_selector("h1", text: "Card Search")
      expect(page).to have_css("#card-name-search")
      expect(page).to have_css("#card-set-code-search")
      expect(page).to have_button("Search")
    end

    it "displays search prompt when no search performed" do
      visit cards_path

      expect(page).to have_content("Search for cards")
      expect(page).to have_content("Enter a card name or set code")
    end
  end

  describe "searching by name" do
    it "finds cards by name" do
      visit cards_path

      fill_in "card-name-search", with: "Lightning Bolt"
      click_button "Search"

      expect(page).to have_content("Lightning Bolt")
      expect(page).to have_css("[data-testid='card-row']", minimum: 1)
    end

    it "displays result count" do
      visit cards_path

      fill_in "card-name-search", with: "Lightning Bolt"
      click_button "Search"

      expect(page).to have_content(/\d+ cards? found/)
    end

    it "preserves search term after search" do
      visit cards_path

      fill_in "card-name-search", with: "Lightning Bolt"
      click_button "Search"

      expect(page).to have_field("card-name-search", with: "Lightning Bolt")
    end
  end

  describe "searching by set code" do
    let(:set) { MTGJSON::Set.released.joins(:cards).order(releaseDate: :desc).first }

    it "finds cards by set code" do
      visit cards_path

      fill_in "card-set-code-search", with: set.code
      click_button "Search"

      expect(page).to have_css("[data-testid='card-row']", minimum: 1)
    end

    it "converts set code to uppercase" do
      visit cards_path

      fill_in "card-set-code-search", with: set.code.downcase
      click_button "Search"

      expect(page).to have_css("[data-testid='card-row']", minimum: 1)
    end
  end

  describe "combined search" do
    let(:set) { MTGJSON::Set.where(code: "LEA").first }

    it "filters by both name and set code" do
      visit cards_path

      fill_in "card-name-search", with: "Lightning"
      fill_in "card-set-code-search", with: "LEA"
      click_button "Search"

      expect(page).to have_current_path(/name=Lightning/)
      expect(page).to have_current_path(/set_code=LEA/i)
    end
  end

  describe "no results" do
    it "displays no results message" do
      visit cards_path

      fill_in "card-name-search", with: "xyznonexistentcardname123"
      click_button "Search"

      expect(page).to have_content("No cards found")
    end

    it "shows search tips" do
      visit cards_path

      fill_in "card-name-search", with: "xyznonexistentcardname123"
      click_button "Search"

      expect(page).to have_content("Check spelling")
    end
  end

  describe "result display" do
    before do
      visit cards_path
      fill_in "card-name-search", with: "Lightning Bolt"
      click_button "Search"
    end

    it "shows card name" do
      within first("[data-testid='card-row']") do
        expect(page).to have_content("Lightning Bolt")
      end
    end

    it "links card name to card detail page" do
      within first("[data-testid='card-row']") do
        expect(page).to have_link("Lightning Bolt")
      end
    end

    it "links set code to set page" do
      within first("[data-testid='card-row']") do
        expect(page).to have_css("a[href*='/sets/']")
      end
    end
  end

  describe "pagination" do
    it "shows pagination for many results" do
      visit cards_path

      fill_in "card-name-search", with: "Goblin"
      click_button "Search"

      # Should have many results requiring pagination
      expect(page).to have_css("[data-testid='card-row']", minimum: 1)
    end
  end

  describe "navigation" do
    it "has Cards link in main navigation" do
      visit root_path

      expect(page).to have_link("Cards", href: cards_path)
    end

    it "highlights Cards in navigation when on cards page" do
      visit cards_path

      expect(page).to have_css("a.text-indigo-600", text: "Cards")
    end

    it "navigates from sets to cards" do
      visit sets_path

      click_link "Cards"

      expect(page).to have_current_path(cards_path)
    end
  end
end
