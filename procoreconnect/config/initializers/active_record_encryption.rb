# Active Record Encryption configuration.
#
# Keys are sourced from environment variables in every environment so they can
# be rotated without code changes. Development and test fall back to fixed
# placeholder values so the app and the spec suite work without secret
# provisioning; production REQUIRES the real env vars and will refuse to boot
# without them.

module ProcoreConnect
  module EncryptionConfig
    DEV_TEST_FALLBACKS = {
      primary_key:         "dev_only_primary_key_change_in_production_now_xxxxxx",
      deterministic_key:   "dev_only_deterministic_key_change_in_production_xxxx",
      key_derivation_salt: "dev_only_key_derivation_salt_change_in_production_xx"
    }.freeze

    def self.value_for(name)
      env_var = "AR_ENCRYPTION_#{name.to_s.upcase}"
      ENV[env_var].presence || begin
        if Rails.env.production?
          raise "Active Record Encryption: missing required env var #{env_var}"
        end
        DEV_TEST_FALLBACKS.fetch(name)
      end
    end
  end
end

ActiveRecord::Encryption.configure(
  primary_key:         ProcoreConnect::EncryptionConfig.value_for(:primary_key),
  deterministic_key:   ProcoreConnect::EncryptionConfig.value_for(:deterministic_key),
  key_derivation_salt: ProcoreConnect::EncryptionConfig.value_for(:key_derivation_salt)
)
