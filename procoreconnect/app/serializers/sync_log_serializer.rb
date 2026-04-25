class SyncLogSerializer < ActiveModel::Serializer
  attributes :id,
             :integration_id,
             :event_type,
             :status,
             :response_code,
             :error_message,
             :payload,
             :created_at,
             :updated_at
end
