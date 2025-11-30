# Phase 1.1: Set Browser

## Feature Overview

Enable users to browse the complete catalog of Magic: The Gathering sets from the MTGJSON database. This provides the entry point for card discovery, allowing users to explore sets by release date and type before drilling down into individual cards.

**Priority**: High (foundational for card discovery)
**Dependencies**: None (first feature in Phase 1)
**Estimated Complexity**: Medium

---

## User Stories

### US-1.1.1: View All Sets
**As a** collector
**I want to** see a list of all MTG sets
**So that** I can browse what sets exist and explore their cards

### US-1.1.2: Sort Sets by Release Date
**As a** collector
**I want to** see sets sorted by release date (newest first)
**So that** I can easily find recent sets and track new releases

### US-1.1.3: Filter Sets by Type
**As a** collector
**I want to** filter sets by type (expansion, core, masters, etc.)
**So that** I can focus on the types of sets I'm interested in

### US-1.1.4: View Set Details
**As a** collector
**I want to** click a set to see its metadata and cards
**So that** I can explore the cards within that set

### US-1.1.5: Paginate Set List
**As a** collector
**I want to** navigate through pages of sets
**So that** the page loads quickly even with 800+ sets

---

## Acceptance Criteria

### AC-1.1.1: Sets Index Page

```gherkin
Feature: Sets Index Page

  Scenario: View all sets
    Given the MTGJSON database contains sets
    When I visit the sets index page
    Then I should see a list of sets
    And each set should display:
      | field        | example                    |
      | code         | "MH3"                      |
      | name         | "Modern Horizons 3"        |
      | type         | "expansion"                |
      | release date | "2024-06-14"               |
      | card count   | "303 cards"                |

  Scenario: Sets sorted by release date
    Given the MTGJSON database contains sets from different years
    When I visit the sets index page
    Then the sets should be ordered by release date descending
    And the most recently released set should appear first

  Scenario: Empty state (no sets)
    Given the MTGJSON database is empty
    When I visit the sets index page
    Then I should see a message "No sets available"
```

### AC-1.1.2: Set Type Filtering

```gherkin
Feature: Set Type Filtering

  Scenario: Filter by expansion sets
    Given the MTGJSON database contains sets of various types
    When I visit the sets index page
    And I select "expansion" from the type filter
    Then I should only see sets with type "expansion"
    And the filter should remain selected

  Scenario: Filter by core sets
    Given the MTGJSON database contains sets of various types
    When I select "core" from the type filter
    Then I should only see sets with type "core"

  Scenario: Clear filter
    Given I have filtered sets by type "expansion"
    When I select "All Types" from the type filter
    Then I should see sets of all types

  Scenario: Filter with no results
    Given the database has no "funny" type sets
    When I select "funny" from the type filter
    Then I should see a message "No sets match your filter"
```

### AC-1.1.3: Pagination

```gherkin
Feature: Sets Pagination

  Scenario: First page of sets
    Given the MTGJSON database contains 100 sets
    And pagination is set to 24 per page
    When I visit the sets index page
    Then I should see 24 sets
    And I should see pagination controls
    And the "Previous" link should be disabled
    And the "Next" link should be enabled

  Scenario: Navigate to next page
    Given I am on the first page of sets
    When I click "Next"
    Then I should see the next 24 sets
    And the URL should include "page=2"
    And the "Previous" link should be enabled

  Scenario: Navigate to previous page
    Given I am on page 2 of sets
    When I click "Previous"
    Then I should see the first page of sets
    And the URL should include "page=1"

  Scenario: Last page of sets
    Given I am on the last page of sets
    Then the "Next" link should be disabled
```

### AC-1.1.4: Set Detail Page

```gherkin
Feature: Set Detail Page

  Scenario: View set details
    Given a set "MH3" exists with name "Modern Horizons 3"
    When I visit the set detail page for "MH3"
    Then I should see the set name "Modern Horizons 3"
    And I should see the set code "MH3"
    And I should see the release date
    And I should see the set type
    And I should see the card count

  Scenario: View cards in set
    Given set "MH3" contains 303 cards
    When I visit the set detail page for "MH3"
    Then I should see a list of cards in the set
    And each card should display its name, type, and rarity

  Scenario: Set not found
    When I visit the set detail page for "INVALID"
    Then I should see a 404 error page
    Or I should be redirected to the sets index with an error message

  Scenario: Paginate cards within set
    Given set "MH3" contains 303 cards
    And pagination is set to 50 per page
    When I visit the set detail page for "MH3"
    Then I should see 50 cards
    And I should see pagination controls for cards
```

### AC-1.1.5: Navigation

```gherkin
Feature: Set Browser Navigation

  Scenario: Navigate from sets index to set detail
    Given I am on the sets index page
    When I click on a set named "Modern Horizons 3"
    Then I should be on the set detail page
    And I should see the cards in that set

  Scenario: Navigate from set detail back to index
    Given I am on a set detail page
    When I click "Back to Sets"
    Then I should be on the sets index page

  Scenario: Click card to view details
    Given I am on a set detail page
    When I click on a card name
    Then I should be on the card detail page
```

---

## Technical Implementation

### Routes

```ruby
# config/routes.rb
resources :sets, only: [:index, :show], param: :code
```

**Routes generated:**
- `GET /sets` → `sets#index`
- `GET /sets/:code` → `sets#show`

### Controller

```ruby
# app/controllers/sets_controller.rb
class SetsController < ApplicationController
  def index
    @sets = MTGJSON::Set.released
                        .order(releaseDate: :desc)
    @sets = @sets.by_type(params[:type]) if params[:type].present?
    @sets = @sets.page(params[:page]).per(24)

    @set_types = MTGJSON::Set.distinct.pluck(:type).compact.sort
  end

  def show
    @set = MTGJSON::Set.find_by!(code: params[:code])
    @cards = @set.cards.order(:number, :name).page(params[:page]).per(50)
  rescue ActiveRecord::RecordNotFound
    redirect_to sets_path, alert: "Set not found"
  end
end
```

### Pagination

Add `kaminari` gem for pagination:

```ruby
# Gemfile
gem "kaminari"
```

### Views

```
app/views/sets/
├── index.html.erb      # Sets list with filters
├── show.html.erb       # Set detail with cards
├── _set.html.erb       # Set card partial
└── _card_row.html.erb  # Card row partial for set view
```

### Set Type Constants

The MTGJSON database includes these set types:
- `expansion` - Standard expansions
- `core` - Core sets
- `masters` - Reprint masters sets
- `draft_innovation` - Draft-focused products
- `commander` - Commander products
- `funny` - Un-sets and joke sets
- `starter` - Starter/intro products
- `box` - Box set products
- `promo` - Promotional cards
- `token` - Token sets
- `memorabilia` - Non-playable products
- `arsenal` - Arsenal products
- `treasure_chest` - MTGO treasure chests
- `masterpiece` - Masterpiece series
- And others...

### Scryfall Set Image Integration (Optional Enhancement)

Set icons can be displayed using Scryfall's SVG API:
```
https://svgs.scryfall.io/sets/{code.downcase}.svg
```

---

## Database Changes

**None required.** This feature uses existing MTGJSON database models.

---

## Test Requirements

### Request Specs

```ruby
# spec/requests/sets_spec.rb
require "rails_helper"

RSpec.describe "Sets", type: :request do
  describe "GET /sets" do
    it "returns successful response" do
      get sets_path
      expect(response).to have_http_status(:ok)
    end

    it "displays sets ordered by release date descending" do
      get sets_path
      # Verify order in response body
    end

    context "with type filter" do
      it "filters sets by type" do
        get sets_path, params: { type: "expansion" }
        expect(response).to have_http_status(:ok)
        # Verify only expansion sets shown
      end
    end

    context "with pagination" do
      it "paginates results" do
        get sets_path, params: { page: 2 }
        expect(response).to have_http_status(:ok)
      end
    end
  end

  describe "GET /sets/:code" do
    context "when set exists" do
      it "returns successful response" do
        set = MTGJSON::Set.first
        get set_path(set.code)
        expect(response).to have_http_status(:ok)
      end

      it "displays set details" do
        set = MTGJSON::Set.first
        get set_path(set.code)
        expect(response.body).to include(set.name)
      end
    end

    context "when set does not exist" do
      it "redirects with error message" do
        get set_path("INVALID")
        expect(response).to redirect_to(sets_path)
        follow_redirect!
        expect(response.body).to include("Set not found")
      end
    end
  end
end
```

### System Specs

```ruby
# spec/system/set_browser_spec.rb
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

    it "filters sets by type" do
      visit sets_path

      select "expansion", from: "type"
      click_button "Filter"

      expect(page).to have_current_path(/type=expansion/)
    end

    it "paginates sets" do
      visit sets_path

      expect(page).to have_css(".pagination")

      click_link "Next"

      expect(page).to have_current_path(/page=2/)
    end
  end

  describe "viewing set details" do
    let(:set) { MTGJSON::Set.released.first }

    it "displays set information" do
      visit set_path(set.code)

      expect(page).to have_content(set.name)
      expect(page).to have_content(set.code)
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

    it "navigates to card detail" do
      visit set_path(set.code)

      first("[data-testid='card-row'] a").click

      expect(page).to have_current_path(%r{/cards/})
    end
  end

  describe "responsive design" do
    it "displays properly on mobile viewport" do
      page.driver.browser.manage.window.resize_to(375, 667)

      visit sets_path

      expect(page).to have_css("[data-testid='set-card']")
    end
  end
end
```

### View Component Tests (Optional)

```ruby
# spec/views/sets/index.html.erb_spec.rb
require "rails_helper"

RSpec.describe "sets/index", type: :view do
  before do
    assign(:sets, MTGJSON::Set.released.limit(5).page(1))
    assign(:set_types, ["core", "expansion"])
  end

  it "renders set cards" do
    render
    expect(rendered).to have_css("[data-testid='set-card']", count: 5)
  end

  it "renders type filter dropdown" do
    render
    expect(rendered).to have_select("type", with_options: ["core", "expansion"])
  end
end
```

---

## UI/UX Specifications

### Sets Index Layout

```
┌─────────────────────────────────────────────────────────────┐
│ Sets                                           [Type Filter]│
│ Browse Magic: The Gathering sets                            │
├─────────────────────────────────────────────────────────────┤
│ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐             │
│ │ MH3         │ │ OTJ         │ │ MKM         │             │
│ │ Modern      │ │ Outlaws of  │ │ Murders at  │             │
│ │ Horizons 3  │ │ Thunder Jun │ │ Karlov...   │             │
│ │             │ │             │ │             │             │
│ │ Expansion   │ │ Expansion   │ │ Expansion   │             │
│ │ 2024-06-14  │ │ 2024-04-19  │ │ 2024-02-09  │             │
│ │ 303 cards   │ │ 292 cards   │ │ 286 cards   │             │
│ └─────────────┘ └─────────────┘ └─────────────┘             │
│                                                             │
│ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐             │
│ │ ...         │ │ ...         │ │ ...         │             │
│ └─────────────┘ └─────────────┘ └─────────────┘             │
│                                                             │
│            « Previous   1  2  3  ...  Next »                │
└─────────────────────────────────────────────────────────────┘
```

### Set Detail Layout

```
┌─────────────────────────────────────────────────────────────┐
│ ← Back to Sets                                              │
├─────────────────────────────────────────────────────────────┤
│ Modern Horizons 3                                           │
│ Code: MH3 | Expansion | Released: 2024-06-14 | 303 cards    │
├─────────────────────────────────────────────────────────────┤
│ Cards in this set                                           │
├─────────────────────────────────────────────────────────────┤
│ # │ Name                    │ Type           │ Rarity       │
│───┼─────────────────────────┼────────────────┼──────────────│
│ 1 │ Ajani, Nacatl Pariah    │ Creature       │ Mythic       │
│ 2 │ Argent Dais             │ Artifact       │ Uncommon     │
│ 3 │ ...                     │ ...            │ ...          │
├─────────────────────────────────────────────────────────────┤
│            « Previous   1  2  3  ...  Next »                │
└─────────────────────────────────────────────────────────────┘
```

### Color Coding for Rarities

- **Common**: Gray badge
- **Uncommon**: Silver/light blue badge
- **Rare**: Gold badge
- **Mythic**: Orange/red badge
- **Special**: Purple badge

---

## Dependencies

- **Kaminari gem**: For pagination
- **MTGJSON database**: Must be set up (`bin/rails mtgjson:setup_test` for tests)

---

## Definition of Done

- [ ] `SetsController` with `index` and `show` actions
- [ ] Routes configured for `/sets` and `/sets/:code`
- [ ] Sets index page displays all released sets
- [ ] Sets sorted by release date (newest first)
- [ ] Type filter dropdown filters sets
- [ ] Pagination works on sets index (24 per page)
- [ ] Set detail page shows set metadata
- [ ] Set detail page lists all cards in set
- [ ] Pagination works on card list (50 per page)
- [ ] Navigation links work (back to sets, to card detail)
- [ ] All request specs pass
- [ ] All system specs pass
- [ ] Responsive design works on mobile
- [ ] Accessible (proper headings, ARIA labels)
- [ ] `bin/rubocop --fix` passes
- [ ] `bin/rspec` passes

---

## Future Enhancements (Not in MVP)

- Set icon images from Scryfall
- Search sets by name
- Sort by different fields (name, card count, etc.)
- Set completion tracking (cards owned vs total)
- Keyboard navigation
