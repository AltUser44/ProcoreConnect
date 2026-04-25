FactoryBot.define do
  factory :integration do
    sequence(:name) { |n| "#{Faker::Company.name} ##{n}" }
    status { "active" }
    api_endpoint { Faker::Internet.url(host: "api.example.com") }
    webhook_url { Faker::Internet.url(host: "hooks.example.com") }
    api_key { Faker::Alphanumeric.alphanumeric(number: 32) }
    last_synced_at { nil }

    trait :paused do
      status { "paused" }
    end

    trait :error do
      status { "error" }
    end

    trait :recently_synced do
      last_synced_at { 1.minute.ago }
    end
  end
end
