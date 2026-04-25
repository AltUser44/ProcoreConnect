class Integration < ApplicationRecord
  STATUSES = %w[active paused error].freeze

  has_many :sync_logs, dependent: :destroy
  has_many :webhook_events, dependent: :destroy

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :api_endpoint, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :active, -> { where(status: "active") }
  scope :paused, -> { where(status: "paused") }
  scope :errored, -> { where(status: "error") }

  def mark_synced!
    update!(last_synced_at: Time.current)
  end

  def active?
    status == "active"
  end
end
