class WebhookEventSerializer < ActiveModel::Serializer
  attributes :id,
             :integration_id,
             :event_type,
             :payload,
             :processed,
             :processed_at,
             :created_at,
             :updated_at
end
