# frozen_string_literal: true

FactoryBot.define do
  factory :catalog do
    sequence(:name) { |n| "Catalog #{n}" }
    source_type { "mtgjson" }
    source_config { {} }

    trait :mtgjson do
      source_type { "mtgjson" }
      source_config { { version: "5.2.2" } }
    end

    trait :api do
      source_type { "api" }
      source_config { { endpoint: "https://api.example.com", api_key: "test_key" } }
    end

    trait :custom do
      source_type { "custom" }
      source_config { {} }
    end
  end
end
