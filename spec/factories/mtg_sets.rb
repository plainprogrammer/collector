# frozen_string_literal: true

FactoryBot.define do
  factory :mtg_set do
    sequence(:code) { |n| "TS#{n.to_s.rjust(2, '0')}" }
    sequence(:name) { |n| "Test Set #{n}" }
    release_date { Date.new(2024, 1, 1) }
    set_type { "expansion" }
    card_count { 300 }
    icon_uri { nil }

    trait :core do
      set_type { "core" }
    end

    trait :masters do
      set_type { "masters" }
    end

    trait :with_icon do
      icon_uri { "https://svgs.scryfall.io/sets/tst.svg" }
    end
  end
end
