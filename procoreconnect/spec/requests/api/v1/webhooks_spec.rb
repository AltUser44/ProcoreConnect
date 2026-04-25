require "rails_helper"

RSpec.describe "Api::V1::Webhooks", type: :request do
  let(:json) { JSON.parse(response.body) }
  let(:integration) { create(:integration) }
  let(:payload) { { "event" => "project.updated", "data" => { "id" => 42, "name" => "Sample Project" } } }

  describe "POST /api/v1/webhooks/:integration_id" do
    it "creates a WebhookEvent and returns 202 Accepted" do
      expect {
        post "/api/v1/webhooks/#{integration.id}",
             params: payload.to_json,
             headers: { "Content-Type" => "application/json", "X-Event-Type" => "project.updated" }
      }.to change(WebhookEvent, :count).by(1)

      expect(response).to have_http_status(:accepted)
      expect(json["id"]).to be_present
      expect(json["event_type"]).to eq("project.updated")
      expect(json["processed"]).to eq(false)
    end

    it "stores the raw payload as JSONB" do
      post "/api/v1/webhooks/#{integration.id}",
           params: payload.to_json,
           headers: { "Content-Type" => "application/json", "X-Event-Type" => "project.updated" }

      event = WebhookEvent.last
      expect(event.payload).to eq(payload)
      expect(event.integration_id).to eq(integration.id)
    end

    it "enqueues a SyncJob with the new webhook event id" do
      expect {
        post "/api/v1/webhooks/#{integration.id}",
             params: payload.to_json,
             headers: { "Content-Type" => "application/json", "X-Event-Type" => "project.updated" }
      }.to have_enqueued_job(SyncJob).with(an_instance_of(Integer))
    end

    it "falls back to a generic event_type when X-Event-Type header is missing" do
      post "/api/v1/webhooks/#{integration.id}",
           params: payload.to_json,
           headers: { "Content-Type" => "application/json" }

      expect(response).to have_http_status(:accepted)
      expect(WebhookEvent.last.event_type).to eq("webhook.received")
    end

    it "returns 404 when the integration does not exist" do
      post "/api/v1/webhooks/0",
           params: payload.to_json,
           headers: { "Content-Type" => "application/json" }

      expect(response).to have_http_status(:not_found)
    end
  end
end
