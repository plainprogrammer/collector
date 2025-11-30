# Phase 1.2: Card Search

## Feature Overview

Enable users to search for cards across the entire MTGJSON database by name and set code. This is the primary discovery mechanism for finding specific cards to add to collections.

**Priority**: High (core discovery feature)
**Dependencies**: Phase 1.1 (Set Browser) - shares card display patterns
**Estimated Complexity**: Medium

---

## User Stories

### US-1.2.1: Search Cards by Name
**As a** collector
**I want to** search for cards by name
**So that** I can find specific cards I own or want

### US-1.2.2: Search Cards by Set Code
**As a** collector
**I want to** filter search results by set code
**So that** I can find a specific printing of a card

### US-1.2.3: View Search Results
**As a** collector
**I want to** see search results with key card information
**So that** I can identify the correct card

### US-1.2.4: Navigate to Card Details
**As a** collector
**I want to** click a search result to view full card details
**So that** I can learn more about a card before adding it

### US-1.2.5: Paginate Search Results
**As a** collector
**I want to** navigate through pages of search results
**So that** I can browse large result sets efficiently

---

## Acceptance Criteria

### AC-1.2.1: Card Search Form

```gherkin
Feature: Card Search Form

  Scenario: Search form is displayed
    When I visit the cards index page
    Then I should see a search form with:
      | field    | type   |
      | name     | text   |
      | set code | text   |
    And I should see a "Search" button

  Scenario: Search with empty form
    Given I am on the cards index page
    When I click "Search" without entering any criteria
    Then I should see a message "Enter a card name or set code to search"
    And no cards should be displayed

  Scenario: Search form preserves values
    Given I searched for "Lightning" in set "LEA"
    When the results are displayed
    Then the search form should show "Lightning" in the name field
    And the search form should show "LEA" in the set code field
```

### AC-1.2.2: Search by Name

```gherkin
Feature: Search by Name

  Scenario: Exact name match
    Given a card named "Lightning Bolt" exists
    When I search for "Lightning Bolt"
    Then I should see "Lightning Bolt" in the results

  Scenario: Partial name match
    Given cards exist with names containing "Lightning"
    When I search for "Lightning"
    Then I should see all cards with "Lightning" in their name
    And results should include "Lightning Bolt", "Lightning Helix", etc.

  Scenario: Case insensitive search
    Given a card named "Lightning Bolt" exists
    When I search for "lightning bolt"
    Then I should see "Lightning Bolt" in the results

  Scenario: No results found
    When I search for "xyznonexistentcard123"
    Then I should see a message "No cards found matching your search"
    And a suggestion to try different search terms

  Scenario: Special characters in name
    Given a card named "Ach! Hans, Run!" exists
    When I search for "Ach! Hans"
    Then I should see "Ach! Hans, Run!" in the results
```

### AC-1.2.3: Search by Set Code

```gherkin
Feature: Search by Set Code

  Scenario: Filter by set code
    Given cards exist in set "MH3"
    When I search with set code "MH3"
    Then I should see only cards from set "MH3"

  Scenario: Set code is case insensitive
    Given cards exist in set "MH3"
    When I search with set code "mh3"
    Then I should see cards from set "MH3"

  Scenario: Invalid set code
    When I search with set code "INVALID"
    Then I should see a message "No cards found matching your search"

  Scenario: Combine name and set code
    Given "Lightning Bolt" exists in multiple sets
    When I search for "Lightning Bolt" in set "LEA"
    Then I should see only the "Limited Edition Alpha" printing
```

### AC-1.2.4: Search Results Display

```gherkin
Feature: Search Results Display

  Scenario: Display card information
    Given I search for "Lightning Bolt"
    Then each result should display:
      | field      | example                     |
      | name       | "Lightning Bolt"            |
      | set name   | "Limited Edition Alpha"     |
      | set code   | "LEA"                       |
      | type       | "Instant"                   |
      | mana cost  | "{R}"                       |
      | rarity     | "Common"                    |

  Scenario: Results are clickable
    Given I have search results
    When I click on a card name
    Then I should navigate to the card detail page

  Scenario: Display result count
    Given 47 cards match my search
    Then I should see "47 cards found"
```

### AC-1.2.5: Pagination

```gherkin
Feature: Search Results Pagination

  Scenario: Paginate large result sets
    Given 150 cards match my search
    And pagination is set to 50 per page
    When I view the search results
    Then I should see 50 cards
    And I should see pagination controls

  Scenario: Maintain search on pagination
    Given I searched for "Goblin"
    And I am on page 1 of results
    When I click "Next"
    Then I should see page 2 of "Goblin" results
    And the search term should be preserved in the URL

  Scenario: Small result set
    Given 10 cards match my search
    When I view the search results
    Then I should see all 10 cards
    And pagination controls should not be shown
```

### AC-1.2.6: Search Performance

```gherkin
Feature: Search Performance

  Scenario: Quick response time
    When I search for a common term like "Creature"
    Then results should appear within 2 seconds

  Scenario: Debounced search (optional enhancement)
    Given I am typing in the search field
    When I type "Ligh" and pause for 300ms
    Then a search should be triggered automatically
```

---

## Technical Implementation

### Routes

```ruby
# config/routes.rb
resources :cards, only: [:index, :show], param: :uuid
```

**Routes generated:**
- `GET /cards` → `cards#index` (search page)
- `GET /cards/:uuid` → `cards#show` (card detail - Phase 1.3)

### Controller

```ruby
# app/controllers/cards_controller.rb
class CardsController < ApplicationController
  def index
    if search_params_present?
      @cards = search_cards
      @result_count = @cards.total_count
    else
      @cards = MTGJSON::Card.none.page(1)
      @show_prompt = true
    end
  end

  def show
    # Implemented in Phase 1.3
  end

  private

  def search_params_present?
    params[:name].present? || params[:set_code].present?
  end

  def search_cards
    cards = MTGJSON::Card.includes(:set)

    if params[:name].present?
      cards = cards.by_name(params[:name])
    end

    if params[:set_code].present?
      cards = cards.by_set(params[:set_code].upcase)
    end

    cards.order(:name, :setCode).page(params[:page]).per(50)
  end
end
```

### Model Enhancements

The existing `MTGJSON::Card` model already has the necessary scopes:

```ruby
# Already exists in app/models/mtgjson/card.rb
scope :by_name, ->(name) { where("name LIKE ?", "%#{sanitize_sql_like(name)}%") }
scope :by_set, ->(set_code) { where(setCode: set_code) }
```

### Views

```
app/views/cards/
├── index.html.erb          # Search form + results
├── show.html.erb           # Card detail (Phase 1.3)
├── _search_form.html.erb   # Reusable search form partial
├── _card.html.erb          # Card result row partial
└── _no_results.html.erb    # Empty state partial
```

### Search Form Partial

```erb
<%# app/views/cards/_search_form.html.erb %>
<%= form_with url: cards_path, method: :get, local: true,
    class: "flex flex-col sm:flex-row gap-4",
    data: { turbo_frame: "search-results" } do |f| %>

  <div class="flex-1">
    <%= f.label :name, "Card Name", class: "sr-only" %>
    <%= f.text_field :name,
        value: params[:name],
        placeholder: "Search by card name...",
        class: "w-full rounded-lg border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500",
        autofocus: true %>
  </div>

  <div class="w-full sm:w-32">
    <%= f.label :set_code, "Set Code", class: "sr-only" %>
    <%= f.text_field :set_code,
        value: params[:set_code],
        placeholder: "Set code",
        maxlength: 5,
        class: "w-full rounded-lg border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 uppercase" %>
  </div>

  <%= f.submit "Search",
      class: "px-6 py-2 bg-indigo-600 text-white font-medium rounded-lg hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 transition-colors" %>
<% end %>
```

### Turbo Frame Integration

Use Turbo Frames for seamless search updates without full page reload:

```erb
<%# app/views/cards/index.html.erb %>
<%= turbo_frame_tag "search-results" do %>
  <%# Search results rendered here %>
<% end %>
```

---

## Database Changes

**None required.** This feature uses existing MTGJSON database models and scopes.

### Performance Considerations

The MTGJSON database should already have indexes on commonly searched fields. Verify indexes exist:

```sql
-- These should exist in the MTGJSON database
CREATE INDEX IF NOT EXISTS idx_cards_name ON cards(name);
CREATE INDEX IF NOT EXISTS idx_cards_setCode ON cards(setCode);
```

If performance is slow, consider adding a composite index:
```sql
CREATE INDEX IF NOT EXISTS idx_cards_name_setCode ON cards(name, setCode);
```

---

## Test Requirements

### Request Specs

```ruby
# spec/requests/cards_spec.rb
require "rails_helper"

RSpec.describe "Cards", type: :request do
  describe "GET /cards" do
    context "without search parameters" do
      it "returns successful response" do
        get cards_path
        expect(response).to have_http_status(:ok)
      end

      it "displays search prompt" do
        get cards_path
        expect(response.body).to include("Enter a card name")
      end

      it "does not display any cards" do
        get cards_path
        expect(response.body).not_to have_css("[data-testid='card-result']")
      end
    end

    context "with name search" do
      it "returns matching cards" do
        get cards_path, params: { name: "Lightning" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Lightning")
      end

      it "handles no results gracefully" do
        get cards_path, params: { name: "xyznonexistent123" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("No cards found")
      end
    end

    context "with set code filter" do
      it "filters by set code" do
        get cards_path, params: { set_code: "LEA" }
        expect(response).to have_http_status(:ok)
      end

      it "accepts lowercase set codes" do
        get cards_path, params: { set_code: "lea" }
        expect(response).to have_http_status(:ok)
      end
    end

    context "with combined search" do
      it "filters by both name and set code" do
        get cards_path, params: { name: "Lightning", set_code: "LEA" }
        expect(response).to have_http_status(:ok)
      end
    end

    context "with pagination" do
      it "paginates results" do
        get cards_path, params: { name: "Creature", page: 2 }
        expect(response).to have_http_status(:ok)
      end

      it "preserves search params in pagination" do
        get cards_path, params: { name: "Goblin", page: 2 }
        expect(response.body).to include("name=Goblin")
      end
    end
  end
end
```

### System Specs

```ruby
# spec/system/card_search_spec.rb
require "rails_helper"

RSpec.describe "Card Search", type: :system do
  before do
    driven_by(:selenium_headless)
  end

  describe "search form" do
    it "displays the search form" do
      visit cards_path

      expect(page).to have_field("name")
      expect(page).to have_field("set_code")
      expect(page).to have_button("Search")
    end

    it "shows search prompt when no query" do
      visit cards_path

      expect(page).to have_content("Enter a card name")
    end
  end

  describe "searching by name" do
    it "finds cards matching the name" do
      visit cards_path

      fill_in "name", with: "Lightning"
      click_button "Search"

      expect(page).to have_css("[data-testid='card-result']", minimum: 1)
      expect(page).to have_content("Lightning")
    end

    it "shows no results message when nothing matches" do
      visit cards_path

      fill_in "name", with: "xyznonexistent123"
      click_button "Search"

      expect(page).to have_content("No cards found")
    end

    it "preserves search term after search" do
      visit cards_path

      fill_in "name", with: "Bolt"
      click_button "Search"

      expect(page).to have_field("name", with: "Bolt")
    end
  end

  describe "searching by set code" do
    it "filters results by set" do
      visit cards_path

      fill_in "set_code", with: "LEA"
      click_button "Search"

      expect(page).to have_css("[data-testid='card-result']", minimum: 1)
    end

    it "accepts lowercase set codes" do
      visit cards_path

      fill_in "set_code", with: "lea"
      click_button "Search"

      expect(page).to have_css("[data-testid='card-result']", minimum: 1)
    end
  end

  describe "combined search" do
    it "filters by both name and set code" do
      visit cards_path

      fill_in "name", with: "Lightning"
      fill_in "set_code", with: "LEA"
      click_button "Search"

      expect(page).to have_css("[data-testid='card-result']")
      expect(page).to have_content("Lightning")
      expect(page).to have_content("LEA")
    end
  end

  describe "search results" do
    before do
      visit cards_path
      fill_in "name", with: "Lightning Bolt"
      click_button "Search"
    end

    it "displays card information" do
      within first("[data-testid='card-result']") do
        expect(page).to have_css("[data-testid='card-name']")
        expect(page).to have_css("[data-testid='card-set']")
        expect(page).to have_css("[data-testid='card-type']")
      end
    end

    it "navigates to card detail when clicked" do
      first("[data-testid='card-result'] a").click

      expect(page).to have_current_path(%r{/cards/})
    end

    it "shows result count" do
      expect(page).to have_content(/\d+ cards? found/)
    end
  end

  describe "pagination" do
    it "shows pagination for large result sets" do
      visit cards_path
      fill_in "name", with: "Creature"
      click_button "Search"

      expect(page).to have_css(".pagination")
    end

    it "maintains search when paginating" do
      visit cards_path
      fill_in "name", with: "Goblin"
      click_button "Search"

      click_link "Next"

      expect(page).to have_field("name", with: "Goblin")
      expect(page).to have_current_path(/page=2/)
    end
  end

  describe "navigation" do
    it "has link in main nav" do
      visit root_path

      expect(page).to have_link("Cards", href: cards_path)
    end
  end
end
```

### View Specs

```ruby
# spec/views/cards/index.html.erb_spec.rb
require "rails_helper"

RSpec.describe "cards/index", type: :view do
  context "with search prompt" do
    before do
      assign(:cards, MTGJSON::Card.none.page(1))
      assign(:show_prompt, true)
    end

    it "renders search form" do
      render
      expect(rendered).to have_field("name")
      expect(rendered).to have_field("set_code")
    end

    it "shows search prompt message" do
      render
      expect(rendered).to include("Enter a card name")
    end
  end

  context "with search results" do
    before do
      assign(:cards, MTGJSON::Card.by_name("Lightning").limit(5).page(1))
      assign(:result_count, 5)
      assign(:show_prompt, false)
    end

    it "renders card results" do
      render
      expect(rendered).to have_css("[data-testid='card-result']", count: 5)
    end

    it "shows result count" do
      render
      expect(rendered).to include("5 cards found")
    end
  end

  context "with no results" do
    before do
      assign(:cards, MTGJSON::Card.none.page(1))
      assign(:result_count, 0)
      assign(:show_prompt, false)
    end

    it "shows no results message" do
      render
      expect(rendered).to include("No cards found")
    end
  end
end
```

---

## UI/UX Specifications

### Search Page Layout

```
┌─────────────────────────────────────────────────────────────┐
│ Card Search                                                 │
│ Find cards in the Magic: The Gathering database             │
├─────────────────────────────────────────────────────────────┤
│ ┌─────────────────────────────────┐ ┌────────┐ ┌──────────┐ │
│ │ Search by card name...          │ │ Set    │ │  Search  │ │
│ └─────────────────────────────────┘ └────────┘ └──────────┘ │
├─────────────────────────────────────────────────────────────┤
│ 47 cards found                                              │
├─────────────────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ Lightning Bolt          Instant    {R}    LEA  Common   │ │
│ │ Limited Edition Alpha                                   │ │
│ └─────────────────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ Lightning Bolt          Instant    {R}    2ED  Common   │ │
│ │ Unlimited Edition                                       │ │
│ └─────────────────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ Lightning Helix         Instant    {R}{W} RAV  Uncommon │ │
│ │ Ravnica: City of Guilds                                 │ │
│ └─────────────────────────────────────────────────────────┘ │
│ ...                                                         │
│                                                             │
│            « Previous   1  2  3  ...  Next »                │
└─────────────────────────────────────────────────────────────┘
```

### Empty State (No Query)

```
┌─────────────────────────────────────────────────────────────┐
│ Card Search                                                 │
│ Find cards in the Magic: The Gathering database             │
├─────────────────────────────────────────────────────────────┤
│ ┌─────────────────────────────────┐ ┌────────┐ ┌──────────┐ │
│ │ Search by card name...          │ │ Set    │ │  Search  │ │
│ └─────────────────────────────────┘ └────────┘ └──────────┘ │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│              🔍                                              │
│                                                             │
│     Enter a card name or set code to search                 │
│                                                             │
│     Examples:                                               │
│       • "Lightning Bolt" - search by name                   │
│       • "MH3" - browse Modern Horizons 3                    │
│       • "Goblin" in "LEA" - find Goblins in Alpha           │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### No Results State

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│              ❌                                              │
│                                                             │
│     No cards found matching "xyznonexistent"                │
│                                                             │
│     Try:                                                    │
│       • Check spelling                                      │
│       • Use partial name (e.g., "Bolt" instead of "Boltt")  │
│       • Remove the set code filter                          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Mana Cost Display

Use mana symbols or text representation:
- `{W}` → White mana
- `{U}` → Blue mana
- `{B}` → Black mana
- `{R}` → Red mana
- `{G}` → Green mana
- `{1}`, `{2}`, etc. → Generic mana
- `{X}` → Variable mana

Consider using CSS background images or inline SVGs for mana symbols (optional enhancement).

---

## Navigation Updates

Add "Cards" link to main navigation:

```erb
<%# app/views/layouts/application.html.erb %>
<div class="hidden sm:flex items-center gap-6">
  <%= link_to "Collections", collections_path, ... %>
  <%= link_to "Sets", sets_path, ... %>
  <%= link_to "Cards", cards_path, ... %>
</div>
```

---

## Dependencies

- **Phase 1.1**: Shares card display patterns and navigation structure
- **Kaminari gem**: For pagination (added in Phase 1.1)
- **MTGJSON database**: Must be available

---

## Definition of Done

- [ ] `CardsController` with `index` action
- [ ] Route configured for `/cards`
- [ ] Search form with name and set code fields
- [ ] Name search with partial matching (case-insensitive)
- [ ] Set code filter (case-insensitive)
- [ ] Combined search works correctly
- [ ] Results display card name, type, mana cost, set, rarity
- [ ] Results are clickable (link to card detail)
- [ ] Result count is displayed
- [ ] Pagination works (50 per page)
- [ ] Search params preserved in URL and form
- [ ] Empty state with helpful message
- [ ] No results state with suggestions
- [ ] Navigation link added to header
- [ ] All request specs pass
- [ ] All system specs pass
- [ ] Responsive design works on mobile
- [ ] Accessible (proper labels, keyboard navigation)
- [ ] `bin/rubocop --fix` passes
- [ ] `bin/rspec` passes

---

## Future Enhancements (Not in MVP)

- Live search with debouncing (Stimulus controller)
- Advanced filters (color, type, rarity, CMC)
- Sort options (name, set, color, CMC)
- Card image thumbnails in results
- Recent searches history
- Search suggestions/autocomplete
- Keyboard shortcuts (/ to focus search)
