module Api
  module V1
    class SyncLogsController < BaseController
      before_action :load_integration

      def index
        sync_logs = @integration.sync_logs.recent
        render json: sync_logs, each_serializer: SyncLogSerializer, status: :ok
      end

      def show
        sync_log = @integration.sync_logs.find(params[:id])
        render json: sync_log, serializer: SyncLogSerializer, status: :ok
      end

      private

      def load_integration
        @integration = Integration.find(params[:integration_id])
      end
    end
  end
end
