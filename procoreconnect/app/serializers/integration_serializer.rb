class IntegrationSerializer < ActiveModel::Serializer
  attributes :id,
             :name,
             :status,
             :webhook_url,
             :webhook_secret,
             :api_endpoint,
             :last_synced_at,
             :sync_logs_count,
             :pending_webhook_events_count,
             :created_at,
             :updated_at

  def sync_logs_count
    object.sync_logs.size
  end

  def pending_webhook_events_count
    object.webhook_events.unprocessed.size
  end
end
