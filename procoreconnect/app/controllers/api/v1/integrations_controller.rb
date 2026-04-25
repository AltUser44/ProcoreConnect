module Api
  module V1
    class IntegrationsController < BaseController
      before_action :load_integration, only: %i[show update destroy]

      def index
        integrations = Integration.order(created_at: :desc)
        render json: integrations, each_serializer: IntegrationSerializer, status: :ok
      end

      def show
        render json: @integration, serializer: IntegrationSerializer, status: :ok
      end

      def create
        integration = Integration.new(integration_params)

        if integration.save
          render json: integration, serializer: IntegrationSerializer, status: :created
        else
          render json: { errors: integration.errors.full_messages }, status: :unprocessable_content
        end
      end

      def update
        if @integration.update(integration_params)
          render json: @integration, serializer: IntegrationSerializer, status: :ok
        else
          render json: { errors: @integration.errors.full_messages }, status: :unprocessable_content
        end
      end

      def destroy
        @integration.destroy
        head :no_content
      end

      private

      def load_integration
        @integration = Integration.find(params[:id])
      end

      def integration_params
        params.require(:integration).permit(:name, :status, :webhook_url, :api_endpoint, :api_key)
      end
    end
  end
end
