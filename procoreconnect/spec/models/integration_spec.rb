require "rails_helper"

RSpec.describe Integration, type: :model do
  describe "factory" do
    it "is valid with default attributes" do
      expect(build(:integration)).to be_valid
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_many(:sync_logs).dependent(:destroy) }
    it { is_expected.to have_many(:webhook_events).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:integration) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive.scoped_to(:user_id) }
    it { is_expected.to validate_presence_of(:api_endpoint) }
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_inclusion_of(:status).in_array(%w[active paused error]) }

    it "allows the same name across different users" do
      user_a = create(:user)
      user_b = create(:user)
      create(:integration, user: user_a, name: "Procore Sandbox")

      expect(build(:integration, user: user_b, name: "Procore Sandbox")).to be_valid
    end
  end

  describe "defaults" do
    it "defaults status to 'active' when not provided" do
      integration = described_class.new(name: "Acme", api_endpoint: "https://api.example.com")
      expect(integration.status).to eq("active")
    end

    it "auto-generates a 64-char hex webhook_secret on create" do
      integration = create(:integration)
      expect(integration.webhook_secret).to match(/\A[a-f0-9]{64}\z/)
    end

    it "does not overwrite an explicitly provided webhook_secret" do
      integration = create(:integration, webhook_secret: "deadbeef" * 8)
      expect(integration.webhook_secret).to eq("deadbeef" * 8)
    end
  end

  describe "api_key encryption" do
    it "stores api_key encrypted at rest and round-trips through the model" do
      plaintext = "super-secret-procore-token-987654321"
      integration = create(:integration, api_key: plaintext)

      raw = ActiveRecord::Base.connection.execute(
        "SELECT api_key FROM integrations WHERE id = #{integration.id}"
      ).first["api_key"]

      expect(raw).to be_present
      expect(raw).not_to eq(plaintext)
      expect(raw).not_to include(plaintext)
      expect(integration.reload.api_key).to eq(plaintext)
    end
  end

  describe "#valid_webhook_signature?" do
    let(:integration) { create(:integration) }
    let(:body)        { '{"order_id":42}' }
    let(:expected)    { OpenSSL::HMAC.hexdigest("SHA256", integration.webhook_secret, body) }

    it "accepts a correct sha256= signature" do
      expect(integration.valid_webhook_signature?("sha256=#{expected}", body)).to be true
    end

    it "rejects a tampered body" do
      expect(integration.valid_webhook_signature?("sha256=#{expected}", "tampered")).to be false
    end

    it "rejects a missing signature" do
      expect(integration.valid_webhook_signature?(nil, body)).to be false
      expect(integration.valid_webhook_signature?("", body)).to be false
    end

    it "rejects a signature without the sha256= prefix" do
      expect(integration.valid_webhook_signature?(expected, body)).to be false
    end

    it "rejects a wrong-length signature without raising" do
      expect(integration.valid_webhook_signature?("sha256=short", body)).to be false
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
