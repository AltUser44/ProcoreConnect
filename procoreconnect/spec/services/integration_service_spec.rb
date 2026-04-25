require "rails_helper"

RSpec.describe IntegrationService do
  let(:integration) do
    create(:integration, api_endpoint: "https://api.example.com/sync", api_key: "k_test_123")
  end
  let(:service) { described_class.new(integration) }
  let(:payload) { { "id" => 42, "name" => "Sample" } }

  describe "#initialize" do
    it "raises when given nil" do
      expect { described_class.new(nil) }.to raise_error(ArgumentError)
    end

    it "raises when given an unpersisted integration" do
      expect { described_class.new(Integration.new) }.to raise_error(ArgumentError)
    end
  end

  describe "#deliver" do
    context "when the upstream returns 2xx" do
      before do
        stub_request(:post, integration.api_endpoint)
          .to_return(status: 200, body: { "ok" => true }.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "returns a successful Result with parsed JSON body" do
        result = service.deliver(payload, event_type: "project.updated")

        expect(result).to be_success
        expect(result.status_code).to eq(200)
        expect(result.body).to eq("ok" => true)
        expect(result.error_message).to be_nil
      end

      it "sends Authorization, Content-Type, and X-Event-Type headers" do
        service.deliver(payload, event_type: "project.updated")

        expect(WebMock).to have_requested(:post, integration.api_endpoint)
          .with(
            headers: {
              "Authorization" => "Bearer k_test_123",
              "Content-Type" => "application/json",
              "Accept" => "application/json",
              "X-Event-Type" => "project.updated",
              "User-Agent" => "ProcoreConnect/1.0"
            }
          )
      end

      it "wraps the payload with integration metadata in the body" do
        service.deliver(payload, event_type: "project.updated")

        expect(WebMock).to have_requested(:post, integration.api_endpoint)
          .with { |req|
            body = JSON.parse(req.body)
            body["integration_id"] == integration.id &&
              body["event_type"] == "project.updated" &&
              body["payload"] == payload
          }
      end

      it "omits Authorization when api_key is blank" do
        integration.update!(api_key: nil)

        service.deliver(payload)

        expect(WebMock).to have_requested(:post, integration.api_endpoint)
          .with { |req| !req.headers.key?("Authorization") }
      end
    end

    context "when the upstream returns a 5xx error" do
      before do
        stub_request(:post, integration.api_endpoint)
          .to_return(status: 503, body: "service unavailable")
      end

      it "returns a failure Result with the status code preserved" do
        result = service.deliver(payload)

        expect(result).to be_failure
        expect(result.status_code).to eq(503)
        expect(result.error_message).to eq("HTTP 503")
      end
    end

    context "when a transport error occurs" do
      before do
        stub_request(:post, integration.api_endpoint).to_raise(SocketError.new("getaddrinfo: nodename nor servname provided"))
      end

      it "returns a failure Result without raising" do
        result = service.deliver(payload)

        expect(result).to be_failure
        expect(result.status_code).to be_nil
        expect(result.error_message).to include("SocketError")
      end
    end
  end
end
