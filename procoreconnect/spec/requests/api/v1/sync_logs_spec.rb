require "rails_helper"

RSpec.describe "Api::V1::SyncLogs", type: :request do
  let(:json) { JSON.parse(response.body) }
  let(:integration) { create(:integration) }
  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }

  describe "authentication" do
    it "returns 401 without a token" do
      get "/api/v1/integrations/#{integration.id}/sync_logs"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/integrations/:integration_id/sync_logs" do
    let!(:older_log) { create(:sync_log, integration: integration, created_at: 2.days.ago) }
    let!(:newer_log) { create(:sync_log, :success, integration: integration, created_at: 1.hour.ago) }
    let!(:other_log) { create(:sync_log, integration: create(:integration)) }

    it "returns 200 with only that integration's sync logs, newest first" do
      get "/api/v1/integrations/#{integration.id}/sync_logs", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json.size).to eq(2)
      expect(json.first["id"]).to eq(newer_log.id)
      expect(json.map { |l| l["id"] }).not_to include(other_log.id)
    end

    it "returns 404 if the integration does not exist" do
      get "/api/v1/integrations/0/sync_logs", headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/integrations/:integration_id/sync_logs/:id" do
    let!(:sync_log) { create(:sync_log, :success, integration: integration) }

    it "returns 200 with the sync log" do
      get "/api/v1/integrations/#{integration.id}/sync_logs/#{sync_log.id}",
          headers: headers

      expect(response).to have_http_status(:ok)
      expect(json["id"]).to eq(sync_log.id)
      expect(json["status"]).to eq("success")
      expect(json["response_code"]).to eq(200)
    end

    it "returns 404 when the sync log does not belong to this integration" do
      foreign_log = create(:sync_log, integration: create(:integration))

      get "/api/v1/integrations/#{integration.id}/sync_logs/#{foreign_log.id}",
          headers: headers

      expect(response).to have_http_status(:not_found)
    end
  end
end
