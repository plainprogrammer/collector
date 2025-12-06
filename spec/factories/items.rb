FactoryBot.define do
  factory :item do
    collection
    storage_unit { nil }
    card_uuid { "test-uuid-#{SecureRandom.hex(8)}" }
    condition { :near_mint }
    finish { :nonfoil }
    language { "en" }
    signed { false }
    altered { false }
    misprint { false }
    grading_service { nil }
    grading_score { nil }
    acquisition_date { nil }
    acquisition_price { nil }
    notes { nil }

    trait :foil do
      finish { :traditional_foil }
    end

    trait :signed do
      signed { true }
    end

    trait :altered do
      altered { true }
    end

    trait :misprint do
      misprint { true }
    end

    trait :graded do
      grading_service { "PSA" }
      grading_score { 9.5 }
    end

    trait :with_acquisition_info do
      acquisition_date { Date.current - 30.days }
      acquisition_price { 25.50 }
      notes { "Purchased at local game store" }
    end

    trait :with_storage_unit do
      storage_unit { association :storage_unit, collection: collection }
    end
  end
end
