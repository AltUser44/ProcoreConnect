class SyncLog < ApplicationRecord
  STATUSES = %w[pending success failed].freeze

  belongs_to :integration

  validates :event_type, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }

  scope :successful, -> { where(status: "success") }
  scope :failed, -> { where(status: "failed") }
  scope :pending, -> { where(status: "pending") }
  scope :recent, -> { order(created_at: :desc) }

  def mark_success!(response_code: 200)
    update!(status: "success", response_code: response_code, error_message: nil)
  end

  def mark_failed!(response_code:, error_message:)
    update!(status: "failed", response_code: response_code, error_message: error_message)
  end
end
