module Api
  module V1
    class WebhookEventsController < BaseController
      before_action :load_integration

      def index
        events = @integration.webhook_events.recent
        render json: events, each_serializer: WebhookEventSerializer, status: :ok
      end

      def show
        event = @integration.webhook_events.find(params[:id])
        render json: event, serializer: WebhookEventSerializer, status: :ok
      end

      private

      def load_integration
        @integration = current_user.integrations.find(params[:integration_id])
      end
    end
  end
end
