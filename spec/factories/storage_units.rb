FactoryBot.define do
  factory :storage_unit do
    collection
    sequence(:name) { |n| "Storage Unit #{n}" }
    storage_unit_type { :box }
    description { nil }
    location { nil }
    parent { nil }
  end
end
