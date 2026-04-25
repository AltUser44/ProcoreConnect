require "rails_helper"

RSpec.describe Integration, type: :model do
  describe "factory" do
    it "is valid with default attributes" do
      expect(build(:integration)).to be_valid
    end
  end

  describe "associations" do
    it { is_expected.to have_many(:sync_logs).dependent(:destroy) }
    it { is_expected.to have_many(:webhook_events).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:integration) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
    it { is_expected.to validate_presence_of(:api_endpoint) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_inclusion_of(:status).in_array(%w[active paused error]) }
  end

  describe "defaults" do
    it "defaults status to 'active' when not provided" do
      integration = described_class.new(name: "Acme", api_endpoint: "https://api.example.com")
      expect(integration.status).to eq("active")
    end
  end

  describe "scopes" do
    let!(:active_integration) { create(:integration) }
    let!(:paused_integration) { create(:integration, :paused) }

    describe ".active" do
      it "returns only active integrations" do
        expect(described_class.active).to contain_exactly(active_integration)
      end
    end
  end

  describe "#mark_synced!" do
    it "updates last_synced_at to the current time" do
      integration = create(:integration)
      freeze_time = Time.current.change(usec: 0)
      allow(Time).to receive(:current).and_return(freeze_time)

      integration.mark_synced!

      expect(integration.reload.last_synced_at).to eq(freeze_time)
    end
  end
end
