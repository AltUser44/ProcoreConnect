class SyncJob < ApplicationJob
  queue_as :default

  # Phase 3 stub: enqueueable so the webhooks controller can rely on it.
  # Phase 4 will implement the real sync flow (HTTP call -> SyncLog update -> mark webhook processed).
  def perform(webhook_event_id)
    webhook_event = WebhookEvent.find_by(id: webhook_event_id)
    return if webhook_event.nil?

    Rails.logger.info(
      "[SyncJob] received webhook_event_id=#{webhook_event_id} integration_id=#{webhook_event.integration_id} " \
      "(stub \u2014 Phase 4 will implement actual outbound sync)"
    )
  end
end
