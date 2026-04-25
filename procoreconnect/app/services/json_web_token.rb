require "jwt"

class JsonWebToken
  ALGORITHM = "HS256".freeze
  DEFAULT_EXPIRATION = 24.hours

  class << self
    def encode(payload, exp = DEFAULT_EXPIRATION.from_now)
      payload = payload.dup
      payload[:exp] = exp.to_i
      JWT.encode(payload, secret_key, ALGORITHM)
    end

    def decode(token)
      decoded, _header = JWT.decode(token, secret_key, true, algorithm: ALGORITHM)
      HashWithIndifferentAccess.new(decoded)
    end

    private

    def secret_key
      ENV["JWT_SECRET"].presence ||
        Rails.application.credentials.secret_key_base ||
        Rails.application.secret_key_base
    end
  end
end
