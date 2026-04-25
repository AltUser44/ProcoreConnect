require "rails_helper"

RSpec.describe JsonWebToken do
  let(:payload) { { user_id: 42 } }

  describe ".encode and .decode" do
    it "round-trips a payload through HS256 with an exp claim" do
      token = JsonWebToken.encode(payload)
      decoded = JsonWebToken.decode(token)

      expect(decoded[:user_id]).to eq(42)
      expect(decoded[:exp]).to be_a(Integer)
      expect(decoded[:exp]).to be > Time.current.to_i
    end

    it "honors a custom expiration" do
      token = JsonWebToken.encode(payload, 5.minutes.from_now)
      decoded = JsonWebToken.decode(token)

      expect(decoded[:exp]).to be_within(5).of(5.minutes.from_now.to_i)
    end

    it "raises when the token is expired" do
      expired_token = JsonWebToken.encode(payload, 1.minute.ago)

      expect { JsonWebToken.decode(expired_token) }.to raise_error(JWT::ExpiredSignature)
    end

    it "raises when the token is malformed" do
      expect { JsonWebToken.decode("not-a-real-token") }.to raise_error(JWT::DecodeError)
    end

    it "raises when the signature is invalid" do
      tampered = JsonWebToken.encode(payload) + "tampered"

      expect { JsonWebToken.decode(tampered) }.to raise_error(JWT::DecodeError)
    end
  end
end
