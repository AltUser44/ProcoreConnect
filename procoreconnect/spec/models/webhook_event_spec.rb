require "rails_helper"

RSpec.describe WebhookEvent, type: :model do
  describe "factory" do
    it "is valid with default attributes" do
      expect(build(:webhook_event)).to be_valid
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:integration) }
  end

  describe "validations" do
    subject { build(:webhook_event) }

    it { is_expected.to validate_presence_of(:event_type) }
  end

  describe "defaults" do
    it "defaults processed to false" do
      event = described_class.new
      expect(event.processed).to eq(false)
    end

    it "defaults payload to an empty hash" do
      event = described_class.new
      expect(event.payload).to eq({})
    end
  end

  describe "#mark_processed!" do
    it "sets processed to true and stamps processed_at" do
      event = create(:webhook_event)
      expect { event.mark_processed! }
        .to change { event.reload.processed }.from(false).to(true)
        .and change { event.reload.processed_at }.from(nil)
    end
  end

  describe "scopes" do
    let(:integration) { create(:integration) }
    let!(:pending_event) { create(:webhook_event, integration: integration) }
    let!(:processed_event) { create(:webhook_event, :processed, integration: integration) }

    describe ".unprocessed" do
      it "returns only events with processed = false" do
        expect(described_class.unprocessed).to contain_exactly(pending_event)
      end
    end

    describe ".processed" do
      it "returns only events with processed = true" do
        expect(described_class.processed).to contain_exactly(processed_event)
      end
    end
  end
end
