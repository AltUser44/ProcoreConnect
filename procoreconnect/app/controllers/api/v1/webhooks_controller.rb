module Api
  module V1
    class WebhooksController < BaseController
      # Inbound third-party webhooks can't carry a user JWT. They should
      # eventually authenticate via shared-secret signature (Phase X);
      # for now we explicitly bypass JWT auth on this endpoint only.
      skip_before_action :authenticate_user!, only: :receive

      before_action :load_integration

      def receive
        webhook_event = @integration.webhook_events.create!(
          event_type: extracted_event_type,
          payload: webhook_payload
        )

        SyncJob.perform_later(webhook_event.id)

        render json: webhook_event, serializer: WebhookEventSerializer, status: :accepted
      end

      private

      def load_integration
        @integration = Integration.find(params[:integration_id])
      end

      # Trust the explicit X-Event-Type header set by the third-party webhook
      # sender. If absent, store a generic default; downstream consumers can
      # introspect the payload to determine the actual event shape.
      def extracted_event_type
        request.headers["X-Event-Type"].presence || "webhook.received"
      end

      # Read the raw request body so wrap_parameters / strong params don't
      # interfere with arbitrary third-party JSON shapes.
      def webhook_payload
        @webhook_payload ||= begin
          body = request.raw_post
          body.present? ? JSON.parse(body) : {}
        rescue JSON::ParserError
          {}
        end
      end
    end
  end
end
