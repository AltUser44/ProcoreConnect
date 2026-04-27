class Integration < ApplicationRecord
  STATUSES = %w[active paused error].freeze

  # at-rest only; non-deterministic enc so we never need to query by api_key
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

  # expect "sha256=<hex hmac of raw body>"; secure_compare to avoid timing leaks
  def valid_webhook_signature?(header_value, raw_body)
    return false if header_value.blank? || webhook_secret.blank?
    return false unless header_value.start_with?("sha256=")

    received   = header_value.sub("sha256=", "")
    expected   = OpenSSL::HMAC.hexdigest("SHA256", webhook_secret, raw_body.to_s)
    ActiveSupport::SecurityUtils.secure_compare(received, expected)
  rescue ArgumentError
    false # length mismatch from secure_compare
  end

  private

  def ensure_webhook_secret
    self.webhook_secret ||= SecureRandom.hex(32)
  end
end
