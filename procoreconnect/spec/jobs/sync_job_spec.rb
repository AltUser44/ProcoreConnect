require "rails_helper"

RSpec.describe SyncJob, type: :job do
  let(:integration) { create(:integration) }
  let(:webhook_event) { create(:webhook_event, integration: integration, event_type: "project.updated") }

  let(:success_result) do
    IntegrationService::Result.new(success: true, status_code: 200, body: { "ok" => true })
  end
  let(:failure_result) do
    IntegrationService::Result.new(
      success: false,
      status_code: 502,
      body: nil,
      error_message: "HTTP 502"
    )
  end

  describe "#perform" do
    context "when IntegrationService succeeds" do
      before do
        allow_any_instance_of(IntegrationService).to receive(:deliver).and_return(success_result)
      end

      it "creates a successful SyncLog" do
        expect {
          described_class.perform_now(webhook_event.id)
        }.to change(SyncLog, :count).by(1)

        log = SyncLog.last
        expect(log.status).to eq("success")
        expect(log.response_code).to eq(200)
        expect(log.event_type).to eq("project.updated")
        expect(log.integration_id).to eq(integration.id)
      end

      it "marks the webhook event as processed" do
        expect {
          described_class.perform_now(webhook_event.id)
        }.to change { webhook_event.reload.processed }.from(false).to(true)
      end

      it "updates the integration's last_synced_at" do
        expect {
          described_class.perform_now(webhook_event.id)
        }.to change { integration.reload.last_synced_at }.from(nil)
      end
    end

    context "when IntegrationService fails" do
      before do
        allow_any_instance_of(IntegrationService).to receive(:deliver).and_return(failure_result)
      end

      it "creates a failed SyncLog with the error captured" do
        expect {
          expect { described_class.perform_now(webhook_event.id) }.to raise_error(SyncJob::SyncFailure)
        }.to change(SyncLog, :count).by(1)

        log = SyncLog.last
        expect(log.status).to eq("failed")
        expect(log.response_code).to eq(502)
        expect(log.error_message).to eq("HTTP 502")
      end

      it "leaves the webhook event unprocessed so it can retry" do
        expect {
          expect { described_class.perform_now(webhook_event.id) }.to raise_error(SyncJob::SyncFailure)
        }.not_to change { webhook_event.reload.processed }
      end

      it "does not stamp last_synced_at" do
        expect {
          expect { described_class.perform_now(webhook_event.id) }.to raise_error(SyncJob::SyncFailure)
        }.not_to change { integration.reload.last_synced_at }
      end
    end

    context "when the webhook event is missing" do
      it "returns silently and creates no logs" do
        expect {
          described_class.perform_now(0)
        }.not_to change(SyncLog, :count)
      end
    end

    context "when the webhook event is already processed" do
      before { webhook_event.mark_processed! }

      it "is a no-op (no SyncLog, no IntegrationService call)" do
        expect_any_instance_of(IntegrationService).not_to receive(:deliver)

        expect {
          described_class.perform_now(webhook_event.id)
        }.not_to change(SyncLog, :count)
      end
    end
  end
end
