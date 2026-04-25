class Integration < ApplicationRecord
  STATUSES = %w[active paused error].freeze

  # api_key is sensitive third-party credential material and must never be
  # readable in plaintext from the DB. Non-deterministic so identical inputs
  # produce different ciphertexts; we never need to query by api_key.
  encrypts :api_key

  belongs_to :user

  has_many :sync_logs, dependent: :destroy
  has_many :webhook_events, dependent: :destroy

  after_initialize :ensure_webhook_secret, if: :new_record?

  validates :name, presence: true, uniqueness: { case_sensitive: false, scope: :user_id }
  validates :api_endpoint, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :webhook_secret, presence: true, uniqueness: true

  scope :active, -> { where(status: "active") }
  scope :paused, -> { where(status: "paused") }
  scope :errored, -> { where(status: "error") }

  def mark_synced!
    update!(last_synced_at: Time.current)
  end

  def active?
    status == "active"
  end

  # Verifies an incoming webhook signature against this integration's secret.
  # Expected header format: "sha256=<hex digest of HMAC-SHA256(secret, raw_body)>"
  # Uses constant-time comparison to avoid leaking secret material via timing.
  def valid_webhook_signature?(header_value, raw_body)
    return false if header_value.blank? || webhook_secret.blank?
    return false unless header_value.start_with?("sha256=")

    received   = header_value.sub("sha256=", "")
    expected   = OpenSSL::HMAC.hexdigest("SHA256", webhook_secret, raw_body.to_s)
    ActiveSupport::SecurityUtils.secure_compare(received, expected)
  rescue ArgumentError
    # secure_compare raises on length mismatch.
    false
  end

  private

  def ensure_webhook_secret
    self.webhook_secret ||= SecureRandom.hex(32)
  end
end
