class WebhookEvent < ApplicationRecord
  belongs_to :integration

  validates :event_type, presence: true

  scope :unprocessed, -> { where(processed: false) }
  scope :processed, -> { where(processed: true) }
  scope :recent, -> { order(created_at: :desc) }

  def mark_processed!
    update!(processed: true, processed_at: Time.current)
  end
end
