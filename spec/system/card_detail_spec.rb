require "rails_helper"

RSpec.describe "Card Detail", type: :system do
  before do
    driven_by(:selenium_headless)
    page.driver.browser.manage.window.resize_to(1024, 768)
  end

  let(:card) { MTGJSON::Card.includes(:set).first }

  describe "viewing card details" do
    before { visit card_path(card.uuid) }

    it "displays the card name" do
      expect(page).to have_selector("h1", text: card.name)
    end

    it "displays the card type" do
      expect(page).to have_content(card.type)
    end

    it "displays the mana cost" do
      expect(page).to have_content(card.manaCost.gsub(/[{}]/, "")) if card.manaCost.present?
    end

    it "displays the set name with link" do
      if card.set
        expect(page).to have_link(href: set_path(card.set.code))
        expect(page).to have_content(card.set.name)
      end
    end

    it "displays the rarity" do
      expect(page).to have_content(card.rarity.capitalize) if card.rarity.present?
    end
  end

  describe "card image" do
    context "when card has Scryfall ID" do
      let(:card_with_image) do
        MTGJSON::Card.joins(:identifiers)
                     .where.not(cardIdentifiers: { scryfallId: nil })
                     .first
      end

      it "displays the card image container" do
        skip "No cards with Scryfall IDs" unless card_with_image
        visit card_path(card_with_image.uuid)
        expect(page).to have_css("[data-testid='card-image-container']")
      end
    end
  end

  describe "format legalities" do
    let(:card_with_legalities) do
      MTGJSON::Card.joins(:legalities).first
    end

    it "displays legalities section" do
      skip "No cards with legalities" unless card_with_legalities
      visit card_path(card_with_legalities.uuid)
      expect(page).to have_content("Legalities")
    end

    it "shows format status" do
      skip "No cards with legalities" unless card_with_legalities
      visit card_path(card_with_legalities.uuid)
      expect(page).to have_css("[data-testid='legality-item']", minimum: 1)
    end
  end

  describe "rulings" do
    context "when card has rulings" do
      let(:card_with_rulings) do
        MTGJSON::Card.joins(:rulings).first
      end

      it "displays rulings section" do
        skip "No cards with rulings" unless card_with_rulings
        visit card_path(card_with_rulings.uuid)
        expect(page).to have_content("Rulings")
      end

      it "shows ruling date and text" do
        skip "No cards with rulings" unless card_with_rulings
        visit card_path(card_with_rulings.uuid)
        expect(page).to have_css("[data-testid='ruling-item']", minimum: 1)
      end
    end

    context "when card has no rulings" do
      let(:card_without_rulings) do
        MTGJSON::Card.left_joins(:rulings)
                     .where(cardRulings: { uuid: nil })
                     .first
      end

      it "does not show rulings section" do
        skip "All cards have rulings in test data" unless card_without_rulings
        visit card_path(card_without_rulings.uuid)
        expect(page).not_to have_content("Rulings")
      end
    end
  end

  describe "other printings" do
    context "when card has multiple printings" do
      let(:card_with_printings) do
        card_name = MTGJSON::Card.group(:name).having("COUNT(*) > 1").pluck(:name).first
        MTGJSON::Card.includes(:set).find_by(name: card_name) if card_name
      end

      it "displays other printings section" do
        skip "No cards with multiple printings" unless card_with_printings
        visit card_path(card_with_printings.uuid)
        expect(page).to have_content("Other Printings")
      end

      it "links to other printing versions" do
        skip "No cards with multiple printings" unless card_with_printings
        visit card_path(card_with_printings.uuid)
        within("[data-testid='other-printings']") do
          expect(page).to have_css("a", minimum: 1)
        end
      end

      it "navigates to other printing" do
        skip "No cards with multiple printings" unless card_with_printings
        visit card_path(card_with_printings.uuid)
        first("[data-testid='other-printings'] a").click
        expect(page).to have_current_path(%r{/cards/})
        expect(page).to have_content(card_with_printings.name)
      end
    end
  end

  describe "navigation" do
    it "has back to search link" do
      visit card_path(card.uuid)
      expect(page).to have_link("Back to Search", href: cards_path)
    end

    it "navigates to set page" do
      skip "Card has no set" unless card.set
      visit card_path(card.uuid)
      # Use JavaScript click to avoid sticky header overlap issues in CI
      find_link("View Set").execute_script("this.click()")
      expect(page).to have_current_path(set_path(card.set.code))
    end
  end

  describe "creature cards" do
    let(:creature) do
      MTGJSON::Card.where("type LIKE ?", "%Creature%")
                   .where.not(power: nil)
                   .first
    end

    it "displays power and toughness" do
      skip "No creature cards in test data" unless creature
      visit card_path(creature.uuid)
      expect(page).to have_content("#{creature.power}/#{creature.toughness}")
    end
  end

  describe "planeswalker cards" do
    let(:planeswalker) do
      MTGJSON::Card.where("type LIKE ?", "%Planeswalker%")
                   .where.not(loyalty: nil)
                   .first
    end

    it "displays loyalty" do
      skip "No planeswalker in test data" unless planeswalker
      visit card_path(planeswalker.uuid)
      # Use CSS selector to find the loyalty label since text-transform varies by browser
      expect(page).to have_css("dt", text: /loyalty/i)
      expect(page).to have_content(planeswalker.loyalty)
    end
  end
end
