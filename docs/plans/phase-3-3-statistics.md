# Phase 3.3: Collection Statistics

## Feature Overview

Provide a dashboard view showing collection composition and statistics. This feature helps collectors understand the makeup of their collection at a glance, answering questions like "How many cards do I own?" and "What colors dominate my collection?"

**Priority**: Medium (valuable insight, not blocking other features)
**Dependencies**: Phase 2 (Items exist in collections)
**Estimated Complexity**: Medium

---

## User Stories

### US-3.3.1: View Total Card Count
**As a** collector
**I want to** see the total number of items in my collection
**So that** I know the size of my collection

### US-3.3.2: See Unique vs Total Count
**As a** collector
**I want to** see how many unique cards I own vs total copies
**So that** I understand my collection depth

### US-3.3.3: View Breakdown by Set
**As a** collector
**I want to** see which sets are most represented in my collection
**So that** I know where my collection is concentrated

### US-3.3.4: View Breakdown by Color
**As a** collector
**I want to** see the color distribution of my collection
**So that** I can identify which colors I favor

### US-3.3.5: View Breakdown by Card Type
**As a** collector
**I want to** see the type distribution (creatures, instants, etc.)
**So that** I understand my collection composition

### US-3.3.6: View Breakdown by Condition
**As a** collector
**I want to** see how many cards are in each condition
**So that** I know the quality of my collection

### US-3.3.7: View Breakdown by Finish
**As a** collector
**I want to** see how many foils vs non-foils I have
**So that** I know my special card distribution

### US-3.3.8: View Rarity Distribution
**As a** collector
**I want to** see how many commons, uncommons, rares, and mythics I have
**So that** I understand the rarity spread

---

## Acceptance Criteria

### AC-3.3.1: Statistics Dashboard Access

```gherkin
Feature: Access Statistics Dashboard

  Scenario: Link to statistics from collection page
    Given I am viewing a collection
    Then I should see a "Statistics" link or tab
    When I click "Statistics"
    Then I should see the collection statistics dashboard

  Scenario: Statistics shows collection name
    Given I am viewing statistics for "My Collection"
    Then I should see "My Collection" in the page header
    And I should see "Statistics" as the page title
```

### AC-3.3.2: Total and Unique Counts

```gherkin
Feature: Item Counts

  Scenario: Total item count
    Given my collection has 150 items
    Then the statistics should show "150 total items"

  Scenario: Unique card count
    Given my collection has 150 items
    And 100 of them are unique cards (some duplicates)
    Then the statistics should show "100 unique cards"

  Scenario: Average copies per card
    Given I have 150 items with 100 unique cards
    Then I should see "1.5 avg copies per card" or similar
```

### AC-3.3.3: Set Distribution

```gherkin
Feature: Set Breakdown

  Scenario: Top sets displayed
    Given my collection has cards from 20 different sets
    Then I should see the top 10 sets by item count
    And each set should show the count and percentage

  Scenario: Set breakdown clickable
    Given I see "MH3 - 45 items (30%)" in the set breakdown
    When I click on "MH3"
    Then I should navigate to items filtered by set "MH3"

  Scenario: See all sets option
    Given my collection has cards from 20 sets
    And only 10 are shown by default
    Then I should see a "View all sets" link
    When I click it
    Then I should see all 20 sets
```

### AC-3.3.4: Color Distribution

```gherkin
Feature: Color Breakdown

  Scenario: Color counts displayed
    Given my collection has cards of various colors
    Then I should see counts for:
      | color      |
      | White      |
      | Blue       |
      | Black      |
      | Red        |
      | Green      |
      | Colorless  |
      | Multicolor |

  Scenario: Color percentages
    Given my collection has 100 items
    And 25 are red cards
    Then the Red row should show "25 (25%)"

  Scenario: Visual color representation
    Then colors should be visually indicated (color coding or icons)

  Scenario: Color breakdown clickable
    When I click on "Red" in the color breakdown
    Then I should navigate to items filtered by color "Red"
```

### AC-3.3.5: Type Distribution

```gherkin
Feature: Type Breakdown

  Scenario: Type counts displayed
    Given my collection has various card types
    Then I should see counts for major types:
      | type         |
      | Creature     |
      | Instant      |
      | Sorcery      |
      | Artifact     |
      | Enchantment  |
      | Planeswalker |
      | Land         |

  Scenario: Type breakdown clickable
    When I click on "Creature" in the type breakdown
    Then I should navigate to items filtered by type "Creature"
```

### AC-3.3.6: Condition Distribution

```gherkin
Feature: Condition Breakdown

  Scenario: Condition counts
    Given my collection has items in various conditions
    Then I should see counts for:
      | condition         |
      | Near Mint         |
      | Lightly Played    |
      | Moderately Played |
      | Heavily Played    |
      | Damaged           |

  Scenario: Condition bar chart
    Then conditions should be displayed as a horizontal bar chart
    And the bar should be colored based on condition quality
```

### AC-3.3.7: Finish Distribution

```gherkin
Feature: Finish Breakdown

  Scenario: Finish counts
    Given my collection has various finishes
    Then I should see counts for:
      | finish           |
      | Non-foil         |
      | Traditional Foil |
      | Etched           |
      | Other Special    |

  Scenario: Foil percentage
    Given I have 100 items
    And 15 are some kind of foil
    Then I should see "15% foil" or similar summary
```

### AC-3.3.8: Rarity Distribution

```gherkin
Feature: Rarity Breakdown

  Scenario: Rarity counts
    Given my collection has cards of various rarities
    Then I should see counts for:
      | rarity   |
      | Common   |
      | Uncommon |
      | Rare     |
      | Mythic   |
      | Special  |

  Scenario: Rarity visual representation
    Then rarities should be color-coded (black, silver, gold, orange)
```

### AC-3.3.9: Empty Collection

```gherkin
Feature: Empty Collection Statistics

  Scenario: No items in collection
    Given my collection has no items
    When I view statistics
    Then I should see "No items in this collection"
    And I should see a link to add cards
```

### AC-3.3.10: Performance

```gherkin
Feature: Statistics Performance

  Scenario: Large collection loads quickly
    Given my collection has 10,000 items
    When I view statistics
    Then the page should load within 3 seconds

  Scenario: Statistics are cached
    Given I view statistics
    When I view them again immediately
    Then the response should be faster (cached)
```

---

## Technical Implementation

### Routes

```ruby
# config/routes.rb
resources :collections do
  member do
    get :statistics
  end
  # ... existing routes
end
```

### Service Object

```ruby
# app/services/collection_statistics.rb
class CollectionStatistics
  attr_reader :collection

  def initialize(collection)
    @collection = collection
    @items = collection.items
    @cards_cache = nil
  end

  def total_count
    @total_count ||= @items.count
  end

  def unique_count
    @unique_count ||= @items.distinct.count(:card_uuid)
  end

  def average_copies
    return 0 if unique_count.zero?
    (total_count.to_f / unique_count).round(2)
  end

  def set_breakdown
    @set_breakdown ||= calculate_set_breakdown
  end

  def color_breakdown
    @color_breakdown ||= calculate_color_breakdown
  end

  def type_breakdown
    @type_breakdown ||= calculate_type_breakdown
  end

  def condition_breakdown
    @condition_breakdown ||= @items.group(:condition).count.transform_keys { |k| Item.conditions.key(k) || k }
  end

  def finish_breakdown
    @finish_breakdown ||= @items.group(:finish).count.transform_keys { |k| Item.finishes.key(k) || k }
  end

  def rarity_breakdown
    @rarity_breakdown ||= calculate_rarity_breakdown
  end

  def foil_count
    @foil_count ||= @items.where.not(finish: :nonfoil).count
  end

  def foil_percentage
    return 0 if total_count.zero?
    ((foil_count.to_f / total_count) * 100).round(1)
  end

  private

  def cards
    @cards_cache ||= load_cards
  end

  def load_cards
    uuids = @items.pluck(:card_uuid).uniq
    MTGJSON::Card.where(uuid: uuids).index_by(&:uuid)
  end

  def calculate_set_breakdown
    # Group items by card_uuid, then look up set
    uuid_counts = @items.group(:card_uuid).count

    set_counts = Hash.new(0)
    uuid_counts.each do |uuid, count|
      card = cards[uuid]
      next unless card
      set_counts[card.setCode] += count
    end

    # Sort by count descending
    set_counts.sort_by { |_, count| -count }.to_h
  end

  def calculate_color_breakdown
    color_counts = {
      "W" => 0, "U" => 0, "B" => 0, "R" => 0, "G" => 0,
      "Colorless" => 0, "Multicolor" => 0
    }

    uuid_counts = @items.group(:card_uuid).count
    uuid_counts.each do |uuid, count|
      card = cards[uuid]
      next unless card

      card_colors = parse_colors(card.colors)

      if card_colors.empty?
        color_counts["Colorless"] += count
      elsif card_colors.size > 1
        color_counts["Multicolor"] += count
        # Also count individual colors
        card_colors.each { |c| color_counts[c] += count if color_counts.key?(c) }
      else
        color_counts[card_colors.first] += count if color_counts.key?(card_colors.first)
      end
    end

    color_counts
  end

  def calculate_type_breakdown
    type_counts = Hash.new(0)
    types_to_track = %w[Creature Instant Sorcery Artifact Enchantment Planeswalker Land]

    uuid_counts = @items.group(:card_uuid).count
    uuid_counts.each do |uuid, count|
      card = cards[uuid]
      next unless card

      types_to_track.each do |type|
        type_counts[type] += count if card.type&.include?(type)
      end
    end

    type_counts.sort_by { |_, count| -count }.to_h
  end

  def calculate_rarity_breakdown
    rarity_counts = Hash.new(0)

    uuid_counts = @items.group(:card_uuid).count
    uuid_counts.each do |uuid, count|
      card = cards[uuid]
      next unless card

      rarity = card.rarity&.capitalize || "Unknown"
      rarity_counts[rarity] += count
    end

    # Sort by rarity order
    rarity_order = %w[Common Uncommon Rare Mythic Special Bonus Unknown]
    rarity_counts.sort_by { |r, _| rarity_order.index(r) || 99 }.to_h
  end

  def parse_colors(colors_string)
    return [] if colors_string.blank?
    JSON.parse(colors_string) rescue []
  end
end
```

### Controller

```ruby
# app/controllers/collections_controller.rb (addition)
class CollectionsController < ApplicationController
  def statistics
    @collection = Collection.find(params[:id])

    # Cache statistics for 5 minutes
    @stats = Rails.cache.fetch("collection_stats_#{@collection.id}", expires_in: 5.minutes) do
      CollectionStatistics.new(@collection)
    end
  end
end
```

### Helper Methods

```ruby
# app/helpers/statistics_helper.rb
module StatisticsHelper
  COLOR_CLASSES = {
    "W" => "bg-amber-100 text-amber-800 border-amber-300",
    "U" => "bg-blue-100 text-blue-800 border-blue-300",
    "B" => "bg-gray-800 text-gray-100 border-gray-600",
    "R" => "bg-red-100 text-red-800 border-red-300",
    "G" => "bg-green-100 text-green-800 border-green-300",
    "Colorless" => "bg-gray-100 text-gray-800 border-gray-300",
    "Multicolor" => "bg-gradient-to-r from-amber-100 via-blue-100 to-green-100 text-gray-800 border-gray-300"
  }.freeze

  COLOR_NAMES = {
    "W" => "White",
    "U" => "Blue",
    "B" => "Black",
    "R" => "Red",
    "G" => "Green",
    "Colorless" => "Colorless",
    "Multicolor" => "Multicolor"
  }.freeze

  RARITY_CLASSES = {
    "Common" => "bg-gray-600",
    "Uncommon" => "bg-gray-400",
    "Rare" => "bg-amber-500",
    "Mythic" => "bg-orange-500",
    "Special" => "bg-purple-500",
    "Bonus" => "bg-purple-400",
    "Unknown" => "bg-gray-300"
  }.freeze

  CONDITION_CLASSES = {
    "near_mint" => "bg-green-500",
    "lightly_played" => "bg-lime-500",
    "moderately_played" => "bg-yellow-500",
    "heavily_played" => "bg-orange-500",
    "damaged" => "bg-red-500"
  }.freeze

  def color_class(color_code)
    COLOR_CLASSES[color_code] || "bg-gray-100 text-gray-800"
  end

  def color_name(color_code)
    COLOR_NAMES[color_code] || color_code
  end

  def rarity_class(rarity)
    RARITY_CLASSES[rarity] || "bg-gray-300"
  end

  def condition_bar_class(condition)
    CONDITION_CLASSES[condition] || "bg-gray-300"
  end

  def percentage(count, total)
    return 0 if total.zero?
    ((count.to_f / total) * 100).round(1)
  end

  def format_percentage(count, total)
    "#{percentage(count, total)}%"
  end
end
```

### View

```erb
<%# app/views/collections/statistics.html.erb %>
<% content_for :title, "Statistics - #{@collection.name}" %>

<article class="w-full">
  <nav class="mb-6">
    <%= link_to @collection, class: "inline-flex items-center gap-1 text-indigo-600 hover:text-indigo-800" do %>
      <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7"/>
      </svg>
      Back to <%= @collection.name %>
    <% end %>
  </nav>

  <header class="mb-8">
    <h1 class="text-3xl font-bold text-gray-900">Collection Statistics</h1>
    <p class="mt-1 text-gray-600"><%= @collection.name %></p>
  </header>

  <% if @stats.total_count.zero? %>
    <div class="text-center py-12 bg-gray-50 rounded-lg">
      <svg class="mx-auto h-12 w-12 text-gray-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z"/>
      </svg>
      <h3 class="mt-2 text-sm font-medium text-gray-900">No items in this collection</h3>
      <p class="mt-1 text-sm text-gray-500">Add some cards to see statistics.</p>
      <div class="mt-4">
        <%= link_to cards_path, class: "inline-flex items-center gap-2 px-4 py-2 bg-indigo-600 text-white rounded-lg hover:bg-indigo-700" do %>
          Browse Cards
        <% end %>
      </div>
    </div>
  <% else %>
    <!-- Summary Cards -->
    <div class="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
      <div class="bg-white rounded-lg border border-gray-200 p-4">
        <dt class="text-sm font-medium text-gray-500">Total Items</dt>
        <dd class="mt-1 text-3xl font-bold text-gray-900"><%= number_with_delimiter(@stats.total_count) %></dd>
      </div>
      <div class="bg-white rounded-lg border border-gray-200 p-4">
        <dt class="text-sm font-medium text-gray-500">Unique Cards</dt>
        <dd class="mt-1 text-3xl font-bold text-gray-900"><%= number_with_delimiter(@stats.unique_count) %></dd>
      </div>
      <div class="bg-white rounded-lg border border-gray-200 p-4">
        <dt class="text-sm font-medium text-gray-500">Avg Copies</dt>
        <dd class="mt-1 text-3xl font-bold text-gray-900"><%= @stats.average_copies %></dd>
      </div>
      <div class="bg-white rounded-lg border border-gray-200 p-4">
        <dt class="text-sm font-medium text-gray-500">Foil Cards</dt>
        <dd class="mt-1 text-3xl font-bold text-gray-900">
          <%= @stats.foil_count %>
          <span class="text-sm font-normal text-gray-500">(<%= @stats.foil_percentage %>%)</span>
        </dd>
      </div>
    </div>

    <div class="grid lg:grid-cols-2 gap-8">
      <!-- Set Distribution -->
      <section class="bg-white rounded-lg border border-gray-200 p-6">
        <h2 class="text-lg font-semibold text-gray-900 mb-4">Sets</h2>
        <div class="space-y-3">
          <% @stats.set_breakdown.first(10).each do |set_code, count| %>
            <div class="flex items-center justify-between">
              <%= link_to collection_items_path(@collection, set: set_code),
                  class: "font-medium text-gray-900 hover:text-indigo-600" do %>
                <%= set_code %>
              <% end %>
              <div class="flex items-center gap-2">
                <div class="w-24 bg-gray-100 rounded-full h-2">
                  <div class="bg-indigo-500 h-2 rounded-full" style="width: <%= percentage(count, @stats.total_count) %>%"></div>
                </div>
                <span class="text-sm text-gray-600 w-20 text-right">
                  <%= count %> (<%= format_percentage(count, @stats.total_count) %>)
                </span>
              </div>
            </div>
          <% end %>
          <% if @stats.set_breakdown.size > 10 %>
            <p class="text-sm text-gray-500 pt-2">
              + <%= @stats.set_breakdown.size - 10 %> more sets
            </p>
          <% end %>
        </div>
      </section>

      <!-- Color Distribution -->
      <section class="bg-white rounded-lg border border-gray-200 p-6">
        <h2 class="text-lg font-semibold text-gray-900 mb-4">Colors</h2>
        <div class="space-y-3">
          <% @stats.color_breakdown.each do |color, count| %>
            <% next if count.zero? %>
            <div class="flex items-center justify-between">
              <%= link_to collection_items_path(@collection, color: color == "Colorless" ? "C" : (color == "Multicolor" ? "M" : color)),
                  class: "flex items-center gap-2 hover:opacity-80" do %>
                <span class="w-6 h-6 rounded-full border flex items-center justify-center text-xs font-bold <%= color_class(color) %>">
                  <%= color == "Colorless" ? "C" : (color == "Multicolor" ? "M" : color) %>
                </span>
                <span class="font-medium text-gray-900"><%= color_name(color) %></span>
              <% end %>
              <div class="flex items-center gap-2">
                <div class="w-24 bg-gray-100 rounded-full h-2">
                  <div class="h-2 rounded-full <%= color == "Multicolor" ? "bg-gradient-to-r from-amber-400 via-blue-400 to-green-400" : "bg-gray-500" %>"
                       style="width: <%= percentage(count, @stats.total_count) %>%"></div>
                </div>
                <span class="text-sm text-gray-600 w-20 text-right">
                  <%= count %> (<%= format_percentage(count, @stats.total_count) %>)
                </span>
              </div>
            </div>
          <% end %>
        </div>
      </section>

      <!-- Type Distribution -->
      <section class="bg-white rounded-lg border border-gray-200 p-6">
        <h2 class="text-lg font-semibold text-gray-900 mb-4">Card Types</h2>
        <div class="space-y-3">
          <% @stats.type_breakdown.each do |type, count| %>
            <% next if count.zero? %>
            <div class="flex items-center justify-between">
              <%= link_to collection_items_path(@collection, type: type),
                  class: "font-medium text-gray-900 hover:text-indigo-600" do %>
                <%= type %>
              <% end %>
              <div class="flex items-center gap-2">
                <div class="w-24 bg-gray-100 rounded-full h-2">
                  <div class="bg-purple-500 h-2 rounded-full" style="width: <%= percentage(count, @stats.total_count) %>%"></div>
                </div>
                <span class="text-sm text-gray-600 w-20 text-right">
                  <%= count %> (<%= format_percentage(count, @stats.total_count) %>)
                </span>
              </div>
            </div>
          <% end %>
        </div>
      </section>

      <!-- Rarity Distribution -->
      <section class="bg-white rounded-lg border border-gray-200 p-6">
        <h2 class="text-lg font-semibold text-gray-900 mb-4">Rarity</h2>
        <div class="space-y-3">
          <% @stats.rarity_breakdown.each do |rarity, count| %>
            <% next if count.zero? %>
            <div class="flex items-center justify-between">
              <div class="flex items-center gap-2">
                <span class="w-3 h-3 rounded-full <%= rarity_class(rarity) %>"></span>
                <span class="font-medium text-gray-900"><%= rarity %></span>
              </div>
              <div class="flex items-center gap-2">
                <div class="w-24 bg-gray-100 rounded-full h-2">
                  <div class="<%= rarity_class(rarity) %> h-2 rounded-full" style="width: <%= percentage(count, @stats.total_count) %>%"></div>
                </div>
                <span class="text-sm text-gray-600 w-20 text-right">
                  <%= count %> (<%= format_percentage(count, @stats.total_count) %>)
                </span>
              </div>
            </div>
          <% end %>
        </div>
      </section>

      <!-- Condition Distribution -->
      <section class="bg-white rounded-lg border border-gray-200 p-6">
        <h2 class="text-lg font-semibold text-gray-900 mb-4">Condition</h2>
        <div class="space-y-3">
          <% Item.conditions.keys.each do |condition| %>
            <% count = @stats.condition_breakdown[condition] || 0 %>
            <% next if count.zero? %>
            <div class="flex items-center justify-between">
              <%= link_to collection_items_path(@collection, condition: condition),
                  class: "font-medium text-gray-900 hover:text-indigo-600" do %>
                <%= condition_display_name(condition) %>
              <% end %>
              <div class="flex items-center gap-2">
                <div class="w-24 bg-gray-100 rounded-full h-2">
                  <div class="<%= condition_bar_class(condition) %> h-2 rounded-full" style="width: <%= percentage(count, @stats.total_count) %>%"></div>
                </div>
                <span class="text-sm text-gray-600 w-20 text-right">
                  <%= count %> (<%= format_percentage(count, @stats.total_count) %>)
                </span>
              </div>
            </div>
          <% end %>
        </div>
      </section>

      <!-- Finish Distribution -->
      <section class="bg-white rounded-lg border border-gray-200 p-6">
        <h2 class="text-lg font-semibold text-gray-900 mb-4">Finish</h2>
        <div class="space-y-3">
          <% Item.finishes.keys.each do |finish| %>
            <% count = @stats.finish_breakdown[finish] || 0 %>
            <% next if count.zero? %>
            <div class="flex items-center justify-between">
              <%= link_to collection_items_path(@collection, finish: finish == "nonfoil" ? "nonfoil" : finish),
                  class: "font-medium text-gray-900 hover:text-indigo-600" do %>
                <%= finish.humanize.titleize %>
              <% end %>
              <div class="flex items-center gap-2">
                <div class="w-24 bg-gray-100 rounded-full h-2">
                  <div class="<%= finish == "nonfoil" ? "bg-gray-400" : "bg-gradient-to-r from-yellow-400 to-orange-400" %> h-2 rounded-full" style="width: <%= percentage(count, @stats.total_count) %>%"></div>
                </div>
                <span class="text-sm text-gray-600 w-20 text-right">
                  <%= count %> (<%= format_percentage(count, @stats.total_count) %>)
                </span>
              </div>
            </div>
          <% end %>
        </div>
      </section>
    </div>
  <% end %>
</article>
```

---

## Database Changes

**None required.** Statistics are computed from existing data.

---

## Test Requirements

### Service Object Specs

```ruby
# spec/services/collection_statistics_spec.rb
require "rails_helper"

RSpec.describe CollectionStatistics do
  let(:collection) { create(:collection) }
  let(:card1) { MTGJSON::Card.first }
  let(:card2) { MTGJSON::Card.second }

  subject { described_class.new(collection) }

  describe "#total_count" do
    it "returns total number of items" do
      create_list(:item, 5, collection: collection, card_uuid: card1.uuid)
      expect(subject.total_count).to eq(5)
    end

    it "returns 0 for empty collection" do
      expect(subject.total_count).to eq(0)
    end
  end

  describe "#unique_count" do
    it "returns count of unique cards" do
      create_list(:item, 3, collection: collection, card_uuid: card1.uuid)
      create_list(:item, 2, collection: collection, card_uuid: card2.uuid)

      expect(subject.unique_count).to eq(2)
    end
  end

  describe "#average_copies" do
    it "calculates average copies per card" do
      create_list(:item, 4, collection: collection, card_uuid: card1.uuid)
      create_list(:item, 2, collection: collection, card_uuid: card2.uuid)

      expect(subject.average_copies).to eq(3.0)
    end

    it "returns 0 for empty collection" do
      expect(subject.average_copies).to eq(0)
    end
  end

  describe "#condition_breakdown" do
    it "groups items by condition" do
      create_list(:item, 3, collection: collection, card_uuid: card1.uuid, condition: :near_mint)
      create_list(:item, 2, collection: collection, card_uuid: card1.uuid, condition: :lightly_played)

      breakdown = subject.condition_breakdown
      expect(breakdown["near_mint"]).to eq(3)
      expect(breakdown["lightly_played"]).to eq(2)
    end
  end

  describe "#finish_breakdown" do
    it "groups items by finish" do
      create_list(:item, 4, collection: collection, card_uuid: card1.uuid, finish: :nonfoil)
      create_list(:item, 1, collection: collection, card_uuid: card1.uuid, finish: :traditional_foil)

      breakdown = subject.finish_breakdown
      expect(breakdown["nonfoil"]).to eq(4)
      expect(breakdown["traditional_foil"]).to eq(1)
    end
  end

  describe "#foil_count" do
    it "counts non-nonfoil items" do
      create_list(:item, 3, collection: collection, card_uuid: card1.uuid, finish: :nonfoil)
      create_list(:item, 2, collection: collection, card_uuid: card1.uuid, finish: :traditional_foil)
      create(:item, collection: collection, card_uuid: card1.uuid, finish: :etched)

      expect(subject.foil_count).to eq(3)
    end
  end

  describe "#foil_percentage" do
    it "calculates foil percentage" do
      create_list(:item, 8, collection: collection, card_uuid: card1.uuid, finish: :nonfoil)
      create_list(:item, 2, collection: collection, card_uuid: card1.uuid, finish: :traditional_foil)

      expect(subject.foil_percentage).to eq(20.0)
    end
  end

  describe "#set_breakdown" do
    it "groups items by set code" do
      # This test depends on actual MTGJSON data
      create(:item, collection: collection, card_uuid: card1.uuid)
      create(:item, collection: collection, card_uuid: card2.uuid)

      breakdown = subject.set_breakdown
      expect(breakdown).to be_a(Hash)
      expect(breakdown.values.sum).to eq(2)
    end
  end

  describe "#rarity_breakdown" do
    it "groups items by rarity" do
      create(:item, collection: collection, card_uuid: card1.uuid)

      breakdown = subject.rarity_breakdown
      expect(breakdown).to be_a(Hash)
      expect(breakdown.values.sum).to eq(1)
    end
  end
end
```

### Request Specs

```ruby
# spec/requests/collection_statistics_spec.rb
require "rails_helper"

RSpec.describe "Collection Statistics", type: :request do
  let(:collection) { create(:collection, name: "Test Collection") }
  let(:card) { MTGJSON::Card.first }

  describe "GET /collections/:id/statistics" do
    context "with items" do
      before do
        create_list(:item, 5, collection: collection, card_uuid: card.uuid, condition: :near_mint)
        create_list(:item, 3, collection: collection, card_uuid: card.uuid, condition: :lightly_played, finish: :traditional_foil)
      end

      it "returns successful response" do
        get statistics_collection_path(collection)
        expect(response).to have_http_status(:ok)
      end

      it "displays total count" do
        get statistics_collection_path(collection)
        expect(response.body).to include("8")
      end

      it "displays condition breakdown" do
        get statistics_collection_path(collection)
        expect(response.body).to include("Near mint")
        expect(response.body).to include("Lightly played")
      end

      it "displays foil percentage" do
        get statistics_collection_path(collection)
        expect(response.body).to include("37.5%")
      end
    end

    context "empty collection" do
      it "shows empty state" do
        get statistics_collection_path(collection)
        expect(response.body).to include("No items")
      end
    end
  end
end
```

### System Specs

```ruby
# spec/system/collection_statistics_spec.rb
require "rails_helper"

RSpec.describe "Collection Statistics", type: :system do
  before { driven_by(:selenium_headless) }

  let(:collection) { create(:collection, name: "Test Collection") }
  let(:card) { MTGJSON::Card.first }

  describe "viewing statistics" do
    before do
      create_list(:item, 5, collection: collection, card_uuid: card.uuid, condition: :near_mint)
      create_list(:item, 3, collection: collection, card_uuid: card.uuid, finish: :traditional_foil)
    end

    it "displays summary cards" do
      visit statistics_collection_path(collection)

      expect(page).to have_content("Total Items")
      expect(page).to have_content("8")
      expect(page).to have_content("Unique Cards")
    end

    it "displays condition breakdown" do
      visit statistics_collection_path(collection)

      expect(page).to have_content("Condition")
      expect(page).to have_content("Near mint")
    end

    it "displays finish breakdown" do
      visit statistics_collection_path(collection)

      expect(page).to have_content("Finish")
      expect(page).to have_content("Traditional Foil")
    end

    it "links to filtered views" do
      visit statistics_collection_path(collection)

      click_link "Near Mint (NM)"

      expect(page).to have_current_path(collection_items_path(collection, condition: "near_mint"))
    end
  end

  describe "empty collection" do
    it "shows empty state message" do
      visit statistics_collection_path(collection)

      expect(page).to have_content("No items in this collection")
      expect(page).to have_link("Browse Cards")
    end
  end

  describe "navigation" do
    before do
      create(:item, collection: collection, card_uuid: card.uuid)
    end

    it "has back link to collection" do
      visit statistics_collection_path(collection)

      click_link "Back to #{collection.name}"

      expect(page).to have_current_path(collection_path(collection))
    end
  end
end
```

### Helper Specs

```ruby
# spec/helpers/statistics_helper_spec.rb
require "rails_helper"

RSpec.describe StatisticsHelper, type: :helper do
  describe "#color_class" do
    it "returns correct class for colors" do
      expect(helper.color_class("R")).to include("red")
      expect(helper.color_class("U")).to include("blue")
      expect(helper.color_class("G")).to include("green")
    end
  end

  describe "#color_name" do
    it "returns full color name" do
      expect(helper.color_name("W")).to eq("White")
      expect(helper.color_name("U")).to eq("Blue")
      expect(helper.color_name("B")).to eq("Black")
    end
  end

  describe "#percentage" do
    it "calculates percentage" do
      expect(helper.percentage(25, 100)).to eq(25.0)
      expect(helper.percentage(1, 3)).to eq(33.3)
    end

    it "handles zero total" do
      expect(helper.percentage(5, 0)).to eq(0)
    end
  end

  describe "#format_percentage" do
    it "returns formatted percentage string" do
      expect(helper.format_percentage(25, 100)).to eq("25.0%")
    end
  end

  describe "#rarity_class" do
    it "returns correct class for rarities" do
      expect(helper.rarity_class("Common")).to include("gray-600")
      expect(helper.rarity_class("Rare")).to include("amber")
      expect(helper.rarity_class("Mythic")).to include("orange")
    end
  end
end
```

---

## UI/UX Specifications

### Statistics Dashboard Layout

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ ← Back to My Collection                                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│ Collection Statistics                                                       │
│ My Collection                                                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│ ┌────────────┐ ┌────────────┐ ┌────────────┐ ┌────────────┐                │
│ │Total Items │ │Unique Cards│ │ Avg Copies │ │ Foil Cards │                │
│ │    1,234   │ │     856    │ │    1.44    │ │ 234 (19%)  │                │
│ └────────────┘ └────────────┘ └────────────┘ └────────────┘                │
│                                                                             │
├────────────────────────────────┬────────────────────────────────────────────┤
│ Sets                           │ Colors                                     │
│ MH3 ████████████ 234 (19%)     │ ⚪ White   ████████ 180 (15%)             │
│ ONE ██████████   189 (15%)     │ 🔵 Blue    ███████  156 (13%)             │
│ BRO ████████     145 (12%)     │ ⚫ Black   ██████   134 (11%)             │
│ DMU ██████       112 (9%)      │ 🔴 Red     █████    120 (10%)             │
│ + 15 more sets                 │ 🟢 Green   █████    118 (10%)             │
├────────────────────────────────┼────────────────────────────────────────────┤
│ Card Types                     │ Rarity                                     │
│ Creature    ████████ 456 (37%) │ ● Common   ████████ 445 (36%)             │
│ Instant     ██████   234 (19%) │ ● Uncommon ██████   312 (25%)             │
│ Sorcery     █████    189 (15%) │ ● Rare     █████    256 (21%)             │
│ Artifact    ████     145 (12%) │ ● Mythic   ███      178 (14%)             │
│ Enchantment ███      112 (9%)  │ ● Special  █         43 (3%)              │
├────────────────────────────────┼────────────────────────────────────────────┤
│ Condition                      │ Finish                                     │
│ Near Mint    ████████ 856 (69%)│ Non-foil  ████████ 1000 (81%)             │
│ LP           ████     234 (19%)│ Trad Foil ██        156 (13%)             │
│ MP           ██       100 (8%) │ Etched    █          56 (5%)              │
│ HP           █         34 (3%) │ Other     ▌          22 (2%)              │
│ Damaged      ▌         10 (1%) │                                            │
└────────────────────────────────┴────────────────────────────────────────────┘
```

---

## Dependencies

- **Phase 2**: Items must exist in collections
- **Phase 3.1**: Filtering links use the filter parameters
- **Rails.cache**: For caching statistics (optional)

---

## Definition of Done

- [ ] Statistics route and controller action implemented
- [ ] CollectionStatistics service object with full functionality
- [ ] Summary cards showing total, unique, avg copies, foil %
- [ ] Set breakdown with top 10 sets and percentages
- [ ] Color breakdown with visual color indicators
- [ ] Type breakdown showing major card types
- [ ] Rarity breakdown with rarity-colored indicators
- [ ] Condition breakdown with condition colors
- [ ] Finish breakdown distinguishing foil types
- [ ] All breakdown items link to filtered item list
- [ ] Empty collection state with helpful message
- [ ] Statistics link accessible from collection page
- [ ] Statistics helper with color/rarity classes
- [ ] Service object specs with full coverage
- [ ] Request specs for statistics endpoint
- [ ] System specs for statistics page
- [ ] Helper specs for formatting methods
- [ ] `bin/ci` passes

---

## Future Enhancements (Not in MVP)

- Charts/graphs using Chart.js or similar
- Trend over time (cards added per month)
- Comparison between collections
- Export statistics as PDF/CSV
- Collection value statistics (Phase 4)
- Most valuable cards list
- Completion percentage for sets
- Statistics caching with background refresh
