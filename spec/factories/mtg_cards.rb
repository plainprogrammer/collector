# frozen_string_literal: true

FactoryBot.define do
  factory :mtg_card do
    association :mtg_set
    sequence(:uuid) { |n| SecureRandom.uuid }
    sequence(:scryfall_id) { |n| SecureRandom.uuid }
    sequence(:name) { |n| "Test Card #{n}" }
    set_code { mtg_set&.code || "TST" }
    sequence(:collector_number) { |n| n.to_s.rjust(3, "0") }
    rarity { "common" }
    type_line { "Creature — Human" }
    mana_cost { "{1}{W}" }
    mana_value { 2.0 }
    colors { [ "W" ] }
    color_identity { [ "W" ] }
    finishes { [ "nonfoil" ] }
    frame_effects { [] }
    promo_types { [] }
    prices { {} }
    source_data { {} }

    trait :rare do
      rarity { "rare" }
    end

    trait :mythic do
      rarity { "mythic" }
    end

    trait :foil_available do
      finishes { [ "nonfoil", "foil" ] }
    end

    trait :foil_only do
      finishes { [ "foil" ] }
    end

    trait :etched_available do
      finishes { [ "nonfoil", "foil", "etched" ] }
    end

    trait :creature do
      type_line { "Creature — Human Soldier" }
      power { "2" }
      toughness { "2" }
    end

    trait :instant do
      type_line { "Instant" }
      power { nil }
      toughness { nil }
    end

    trait :sorcery do
      type_line { "Sorcery" }
      power { nil }
      toughness { nil }
    end

    trait :land do
      type_line { "Basic Land — Plains" }
      mana_cost { nil }
      mana_value { 0 }
      colors { [] }
      color_identity { [ "W" ] }
      power { nil }
      toughness { nil }
    end

    trait :artifact do
      type_line { "Artifact" }
      colors { [] }
      color_identity { [] }
      power { nil }
      toughness { nil }
    end

    trait :multicolor do
      mana_cost { "{U}{R}" }
      colors { [ "U", "R" ] }
      color_identity { [ "U", "R" ] }
    end
  end
end
