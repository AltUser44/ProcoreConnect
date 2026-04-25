FactoryBot.define do
  factory :webhook_event do
    integration
    event_type { "project.created" }
    payload { { "id" => SecureRandom.uuid, "data" => { "name" => "Sample" } } }
    processed { false }
    processed_at { nil }

    trait :processed do
      processed { true }
      processed_at { Time.current }
    end
  end
end
