require "rails_helper"

RSpec.describe "Api::V1::Integrations", type: :request do
  let(:json) { JSON.parse(response.body) }
  let(:user) { create(:user) }
  let(:headers) { auth_headers(user) }
  let(:other_user) { create(:user) }

  describe "authentication" do
    it "returns 401 without a token" do
      get "/api/v1/integrations"

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/integrations" do
    let!(:mine_a) { create(:integration, user: user, name: "Procore A") }
    let!(:mine_b) { create(:integration, :paused, user: user, name: "Procore B") }
    let!(:theirs) { create(:integration, user: other_user, name: "Foreign Co") }

    it "returns only the current user's integrations" do
      get "/api/v1/integrations", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json.size).to eq(2)
      expect(json.map { |i| i["name"] }).to contain_exactly("Procore A", "Procore B")
    end

    it "does not expose api_key" do
      get "/api/v1/integrations", headers: headers

      expect(json.first.keys).not_to include("api_key")
    end
  end

  describe "GET /api/v1/integrations/:id" do
    let(:integration) { create(:integration, user: user) }

    it "returns 200 with the integration" do
      get "/api/v1/integrations/#{integration.id}", headers: headers

      expect(response).to have_http_status(:ok)
      expect(json["id"]).to eq(integration.id)
      expect(json["name"]).to eq(integration.name)
      expect(json["sync_logs_count"]).to eq(0)
    end

    it "returns 404 when integration is missing" do
      get "/api/v1/integrations/0", headers: headers

      expect(response).to have_http_status(:not_found)
      expect(json["error"]).to be_present
    end

    it "returns 404 when accessing another user's integration" do
      foreign = create(:integration, user: other_user)

      get "/api/v1/integrations/#{foreign.id}", headers: headers

      expect(response).to have_http_status(:not_found)
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

    it "creates an integration scoped to current_user and returns 201" do
      expect {
        post "/api/v1/integrations", params: valid_params, headers: headers, as: :json
      }.to change(user.integrations, :count).by(1)

      expect(response).to have_http_status(:created)
      expect(json["name"]).to eq("Procore Sandbox")
      expect(json["status"]).to eq("active")
      expect(json["webhook_secret"]).to match(/\A[a-f0-9]{64}\z/)
    end

    it "returns 422 with errors on invalid params" do
      post "/api/v1/integrations",
           params: { integration: { name: "" } },
           headers: headers,
           as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]).to be_present
    end

    it "allows two users to have integrations with the same name" do
      create(:integration, user: other_user, name: "Procore Sandbox")

      post "/api/v1/integrations", params: valid_params, headers: headers, as: :json

      expect(response).to have_http_status(:created)
    end
  end

  describe "PUT /api/v1/integrations/:id" do
    let(:integration) { create(:integration, user: user) }

    it "updates the integration and returns 200" do
      put "/api/v1/integrations/#{integration.id}",
          params: { integration: { status: "paused" } },
          headers: headers,
          as: :json

      expect(response).to have_http_status(:ok)
      expect(json["status"]).to eq("paused")
      expect(integration.reload.status).to eq("paused")
    end

    it "returns 404 when updating another user's integration" do
      foreign = create(:integration, user: other_user)

      put "/api/v1/integrations/#{foreign.id}",
          params: { integration: { status: "paused" } },
          headers: headers,
          as: :json

      expect(response).to have_http_status(:not_found)
      expect(foreign.reload.status).not_to eq("paused")
    end

    it "returns 422 on invalid update" do
      put "/api/v1/integrations/#{integration.id}",
          params: { integration: { status: "bogus" } },
          headers: headers,
          as: :json

      expect(response).to have_http_status(:unprocessable_content)
      expect(json["errors"]).to be_present
    end
  end

  describe "DELETE /api/v1/integrations/:id" do
    let!(:integration) { create(:integration, user: user) }

    it "destroys the integration and returns 204" do
      expect {
        delete "/api/v1/integrations/#{integration.id}", headers: headers
      }.to change(user.integrations, :count).by(-1)

      expect(response).to have_http_status(:no_content)
    end

    it "returns 404 and does not destroy another user's integration" do
      foreign = create(:integration, user: other_user)

      expect {
        delete "/api/v1/integrations/#{foreign.id}", headers: headers
      }.not_to change(Integration, :count)

      expect(response).to have_http_status(:not_found)
    end
  end
end
