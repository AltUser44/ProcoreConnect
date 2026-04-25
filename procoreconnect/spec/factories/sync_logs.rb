FactoryBot.define do
  factory :sync_log do
    integration
    event_type { "project.updated" }
    payload { { "id" => SecureRandom.uuid, "source" => "test" } }
    status { "pending" }
    response_code { nil }
    error_message { nil }

    trait :success do
      status { "success" }
      response_code { 200 }
    end

    trait :failed do
      status { "failed" }
      response_code { 500 }
      error_message { "Upstream service error" }
    end
  end
end
