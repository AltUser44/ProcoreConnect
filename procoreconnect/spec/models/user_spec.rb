require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to allow_value("ada@example.com").for(:email) }
    it { is_expected.not_to allow_value("not-an-email").for(:email) }
    it { is_expected.to validate_length_of(:password).is_at_least(8) }
    it { is_expected.to have_secure_password }
  end

  describe "email normalization" do
    it "downcases and strips email before saving" do
      user = create(:user, email: "  ADA@Example.COM  ")
      expect(user.reload.email).to eq("ada@example.com")
    end
  end

  describe "#authenticate" do
    let(:user) { create(:user, password: "supersecret123", password_confirmation: "supersecret123") }

    it "returns the user when password is correct" do
      expect(user.authenticate("supersecret123")).to eq(user)
    end

    it "returns false when password is wrong" do
      expect(user.authenticate("wrong-password")).to be_falsey
    end
  end
end
