require "rails_helper"

RSpec.describe "Api::V1::Webhooks", type: :request do
  let(:json)        { JSON.parse(response.body) }
  let(:integration) { create(:integration) }
  let(:payload)     { { "event" => "project.updated", "data" => { "id" => 42, "name" => "Sample Project" } } }
  let(:body)        { payload.to_json }

  def signed_headers(secret: integration.webhook_secret, body: self.body, event_type: "project.updated")
    sig = OpenSSL::HMAC.hexdigest("SHA256", secret, body)
    {
      "Content-Type"        => "application/json",
      "X-Event-Type"        => event_type,
      "X-Webhook-Signature" => "sha256=#{sig}"
    }.compact
  end

  describe "POST /api/v1/webhooks/:integration_id" do
    context "with a valid HMAC signature" do
      it "creates a WebhookEvent and returns 202 Accepted" do
        expect {
          post "/api/v1/webhooks/#{integration.id}", params: body, headers: signed_headers
        }.to change(WebhookEvent, :count).by(1)

        expect(response).to have_http_status(:accepted)
        expect(json["id"]).to be_present
        expect(json["event_type"]).to eq("project.updated")
        expect(json["processed"]).to eq(false)
      end

      it "stores the raw payload as JSONB" do
        post "/api/v1/webhooks/#{integration.id}", params: body, headers: signed_headers

        event = WebhookEvent.last
        expect(event.payload).to eq(payload)
        expect(event.integration_id).to eq(integration.id)
      end

      it "enqueues a SyncJob with the new webhook event id" do
        expect {
          post "/api/v1/webhooks/#{integration.id}", params: body, headers: signed_headers
        }.to have_enqueued_job(SyncJob).with(an_instance_of(Integer))
      end

      it "falls back to a generic event_type when X-Event-Type header is missing" do
        post "/api/v1/webhooks/#{integration.id}",
             params: body,
             headers: signed_headers(event_type: nil)

        expect(response).to have_http_status(:accepted)
        expect(WebhookEvent.last.event_type).to eq("webhook.received")
      end
    end

    context "with an invalid signature" do
      it "returns 401 when the signature is missing entirely" do
        post "/api/v1/webhooks/#{integration.id}",
             params: body,
             headers: { "Content-Type" => "application/json" }

        expect(response).to have_http_status(:unauthorized)
        expect(json["error"]).to match(/signature/i)
      end

      it "returns 401 when the signature is forged with the wrong secret" do
        bad_headers = signed_headers(secret: "this-is-not-the-right-secret")

        post "/api/v1/webhooks/#{integration.id}", params: body, headers: bad_headers

        expect(response).to have_http_status(:unauthorized)
      end

      it "returns 401 when the body has been tampered after signing" do
        headers = signed_headers
        post "/api/v1/webhooks/#{integration.id}",
             params: body.sub("Sample Project", "Tampered Project"),
             headers: headers

        expect(response).to have_http_status(:unauthorized)
      end

      it "does not create a WebhookEvent on rejection" do
        expect {
          post "/api/v1/webhooks/#{integration.id}",
               params: body,
               headers: { "Content-Type" => "application/json" }
        }.not_to change(WebhookEvent, :count)
      end

      it "does not enqueue a SyncJob on rejection" do
        expect {
          post "/api/v1/webhooks/#{integration.id}",
               params: body,
               headers: { "Content-Type" => "application/json" }
        }.not_to have_enqueued_job(SyncJob)
      end
    end

    it "returns 404 when the integration does not exist" do
      post "/api/v1/webhooks/0",
           params: body,
           headers: { "Content-Type" => "application/json", "X-Webhook-Signature" => "sha256=anything" }

      expect(response).to have_http_status(:not_found)
    end
  end
end
