class SyncJob < ApplicationJob
  queue_as :sync

  # Sidekiq retry budget (used when the queue adapter is :sidekiq).
  sidekiq_options retry: 5 if respond_to?(:sidekiq_options)

  # Drives the outbound sync for a single WebhookEvent:
  #   1. Find the event (no-op if missing or already processed)
  #   2. Open a SyncLog with status "pending"
  #   3. Hand off to IntegrationService for the HTTP call
  #   4. Stamp the SyncLog success/failure based on the result
  #   5. Mark the WebhookEvent processed
  #   6. On success, bump the integration's last_synced_at
  #   7. Re-raise on failure so Sidekiq's retry middleware can take over
  def perform(webhook_event_id)
    event = WebhookEvent.find_by(id: webhook_event_id)
    return if event.nil? || event.processed?

    integration = event.integration
    sync_log = integration.sync_logs.create!(
      event_type: event.event_type,
      payload: event.payload,
      status: "pending"
    )

    result = IntegrationService.new(integration).deliver(event.payload, event_type: event.event_type)

    if result.success?
      sync_log.mark_success!(response_code: result.status_code)
      event.mark_processed!
      integration.mark_synced!
    else
      sync_log.mark_failed!(
        response_code: result.status_code,
        error_message: result.error_message
      )
      # Re-raise so Sidekiq's retry middleware can replay; the WebhookEvent
      # stays unprocessed until a retry succeeds (or the job is killed).
      raise SyncFailure, "SyncJob failed for webhook_event=#{event.id}: #{result.error_message}"
    end
  end

  class SyncFailure < StandardError; end
end
