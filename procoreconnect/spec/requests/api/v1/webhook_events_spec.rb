require "rails_helper"

RSpec.describe "Api::V1::WebhookEvents", type: :request do
  let(:json) { JSON.parse(response.body) }
  let(:integration) { create(:integration) }
  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }

  describe "authentication" do
    it "returns 401 without a token" do
      get "/api/v1/integrations/#{integration.id}/webhook_events"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/integrations/:integration_id/webhook_events" do
    let!(:older_event) { create(:webhook_event, integration: integration, created_at: 2.days.ago) }
    let!(:newer_event) { create(:webhook_event, :processed, integration: integration, created_at: 1.hour.ago) }
    let!(:other_event) { create(:webhook_event, integration: create(:integration)) }

    it "returns this integration's events newest-first with processed flags" do
      get "/api/v1/integrations/#{integration.id}/webhook_events", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json.size).to eq(2)
      expect(json.first["id"]).to eq(newer_event.id)
      expect(json.first["processed"]).to eq(true)
      expect(json.map { |e| e["id"] }).not_to include(other_event.id)
    end
  end

  describe "GET /api/v1/integrations/:integration_id/webhook_events/:id" do
    let!(:event) { create(:webhook_event, integration: integration) }

    it "returns 200 with the event payload" do
      get "/api/v1/integrations/#{integration.id}/webhook_events/#{event.id}",
          headers: headers

      expect(response).to have_http_status(:ok)
      expect(json["id"]).to eq(event.id)
      expect(json["payload"]).to be_a(Hash)
    end

    it "returns 404 if the event belongs to another integration" do
      foreign_event = create(:webhook_event, integration: create(:integration))

      get "/api/v1/integrations/#{integration.id}/webhook_events/#{foreign_event.id}",
          headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
