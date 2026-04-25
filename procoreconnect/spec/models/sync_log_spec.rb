require "rails_helper"

RSpec.describe SyncLog, type: :model do
  describe "factory" do
    it "is valid with default attributes" do
      expect(build(:sync_log)).to be_valid
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:integration) }
  end

  describe "validations" do
    subject { build(:sync_log) }

    it { is_expected.to validate_presence_of(:event_type) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_inclusion_of(:status).in_array(%w[pending success failed]) }
  end

  describe "defaults" do
    it "defaults status to 'pending'" do
      log = described_class.new
      expect(log.status).to eq("pending")
    end

    it "defaults payload to an empty hash" do
      log = described_class.new
      expect(log.payload).to eq({})
    end
  end

  describe "scopes" do
    let(:integration) { create(:integration) }
    let!(:pending_log) { create(:sync_log, integration: integration) }
    let!(:success_log) { create(:sync_log, :success, integration: integration) }
    let!(:failed_log) { create(:sync_log, :failed, integration: integration) }

    describe ".successful" do
      it "returns only sync logs with status success" do
        expect(described_class.successful).to contain_exactly(success_log)
      end
    end

    describe ".failed" do
      it "returns only sync logs with status failed" do
        expect(described_class.failed).to contain_exactly(failed_log)
      end
    end

    describe ".recent" do
      it "orders sync logs by created_at descending" do
        expect(described_class.recent.first).to eq(failed_log)
      end
    end
  end
end
