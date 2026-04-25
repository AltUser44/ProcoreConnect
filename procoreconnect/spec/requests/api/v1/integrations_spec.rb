require "rails_helper"

RSpec.describe "Api::V1::Integrations", type: :request do
  let(:json) { JSON.parse(response.body) }

  describe "GET /api/v1/integrations" do
    let!(:integration_a) { create(:integration, name: "Procore A") }
    let!(:integration_b) { create(:integration, :paused, name: "Procore B") }

    it "returns 200 with all integrations" do
      get "/api/v1/integrations"

      expect(response).to have_http_status(:ok)
      expect(json.size).to eq(2)
      expect(json.map { |i| i["name"] }).to contain_exactly("Procore A", "Procore B")
    end

    it "does not expose api_key" do
      get "/api/v1/integrations"

      expect(json.first.keys).not_to include("api_key")
    end
  end

  describe "GET /api/v1/integrations/:id" do
    let(:integration) { create(:integration) }

    it "returns 200 with the integration" do
      get "/api/v1/integrations/#{integration.id}"

      expect(response).to have_http_status(:ok)
      expect(json["id"]).to eq(integration.id)
      expect(json["name"]).to eq(integration.name)
      expect(json["sync_logs_count"]).to eq(0)
    end

    it "returns 404 when integration is missing" do
      get "/api/v1/integrations/0"

      expect(response).to have_http_status(:not_found)
      expect(json["error"]).to be_present
    end
  end

  describe "POST /api/v1/integrations" do
    let(:valid_params) do
      {
        integration: {
          name: "Procore Sandbox",
          api_endpoint: "https://api.procore.com/rest/v1.0",
          api_key: "secret-token",
          webhook_url: "https://hooks.example.com/procore"
        }
      }
    end

    it "creates an integration and returns 201" do
      expect {
        post "/api/v1/integrations", params: valid_params, as: :json
      }.to change(Integration, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json["name"]).to eq("Procore Sandbox")
      expect(json["status"]).to eq("active")
    end

    it "returns 422 with errors on invalid params" do
      post "/api/v1/integrations",
           params: { integration: { name: "" } },
           as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]).to be_present
    end
  end

  describe "PUT /api/v1/integrations/:id" do
    let(:integration) { create(:integration) }

    it "updates the integration and returns 200" do
      put "/api/v1/integrations/#{integration.id}",
          params: { integration: { status: "paused" } },
          as: :json

      expect(response).to have_http_status(:ok)
      expect(json["status"]).to eq("paused")
      expect(integration.reload.status).to eq("paused")
    end

    it "returns 422 on invalid update" do
      put "/api/v1/integrations/#{integration.id}",
          params: { integration: { status: "bogus" } },
          as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]).to be_present
    end
  end

  describe "DELETE /api/v1/integrations/:id" do
    let!(:integration) { create(:integration) }

    it "destroys the integration and returns 204" do
      expect {
        delete "/api/v1/integrations/#{integration.id}"
      }.to change(Integration, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end
  end
end
