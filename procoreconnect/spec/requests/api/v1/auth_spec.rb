require "rails_helper"

RSpec.describe "Api::V1::Auth", type: :request do
  let(:json) { JSON.parse(response.body) }

  describe "POST /api/v1/auth/register" do
    context "with valid params" do
      let(:params) { { email: "ada@example.com", password: "supersecret123" } }

      it "creates a user and returns a JWT" do
        expect {
          post "/api/v1/auth/register", params: params, as: :json
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(json["token"]).to be_a(String).and(be_present)
        expect(json["user"]["email"]).to eq("ada@example.com")
        expect(json["user"]).not_to have_key("password_digest")
      end
    end

    context "with a duplicate email" do
      before { create(:user, email: "ada@example.com") }

      it "returns 422 with errors" do
        post "/api/v1/auth/register",
             params: { email: "ada@example.com", password: "supersecret123" },
             as: :json

        expect(response).to have_http_status(:unprocessable_content)
        expect(json["errors"]).to include(match(/email/i))
      end
    end

    context "with a too-short password" do
      it "returns 422" do
        post "/api/v1/auth/register",
             params: { email: "x@y.com", password: "short" },
             as: :json

        expect(response).to have_http_status(:unprocessable_content)
        expect(json["errors"]).to include(match(/password/i))
      end
    end
  end

  describe "POST /api/v1/auth/login" do
    let!(:user) { create(:user, email: "ada@example.com", password: "supersecret123", password_confirmation: "supersecret123") }

    it "returns a JWT for valid credentials" do
      post "/api/v1/auth/login",
           params: { email: "ada@example.com", password: "supersecret123" },
           as: :json

      expect(response).to have_http_status(:ok)
      expect(json["token"]).to be_a(String).and(be_present)
      expect(json["user"]["email"]).to eq("ada@example.com")

      decoded = JsonWebToken.decode(json["token"])
      expect(decoded[:user_id]).to eq(user.id)
    end

    it "is case-insensitive on email" do
      post "/api/v1/auth/login",
           params: { email: "ADA@example.com", password: "supersecret123" },
           as: :json

      expect(response).to have_http_status(:ok)
    end

    it "returns 401 for wrong password" do
      post "/api/v1/auth/login",
           params: { email: "ada@example.com", password: "wrong" },
           as: :json

      expect(response).to have_http_status(:unauthorized)
      expect(json["error"]).to be_present
    end

    it "returns 401 for unknown email" do
      post "/api/v1/auth/login",
           params: { email: "ghost@example.com", password: "supersecret123" },
           as: :json

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/v1/auth/me" do
    let(:user) { create(:user) }

    it "returns the current user when authenticated" do
      get "/api/v1/auth/me", headers: auth_headers(user)

      expect(response).to have_http_status(:ok)
      expect(json["id"]).to eq(user.id)
      expect(json["email"]).to eq(user.email)
    end

    it "returns 401 without a token" do
      get "/api/v1/auth/me"

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 with an invalid token" do
      get "/api/v1/auth/me", headers: { "Authorization" => "Bearer not-a-real-token" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 with an expired token" do
      expired = JsonWebToken.encode({ user_id: user.id }, 1.minute.ago)
      get "/api/v1/auth/me", headers: { "Authorization" => "Bearer #{expired}" }

      expect(response).to have_http_status(:unauthorized)
      expect(json["error"]).to match(/expired/i)
    end
  end
end
