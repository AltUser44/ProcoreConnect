module Api
  module V1
    class AuthController < BaseController
      skip_before_action :authenticate_user!, only: %i[register login]

      def register
        user = User.new(user_params)
        if user.save
          render json: auth_payload(user), status: :created
        else
          render json: { errors: user.errors.full_messages }, status: :unprocessable_content
        end
      end

      def login
        user = User.find_by("LOWER(email) = ?", params[:email].to_s.strip.downcase)

        if user&.authenticate(params[:password])
          render json: auth_payload(user), status: :ok
        else
          render json: { error: "Invalid email or password" }, status: :unauthorized
        end
      end

      def me
        render json: current_user, serializer: UserSerializer, status: :ok
      end

      def logout
        # With stateless JWTs there's nothing to revoke server-side without a
        # token blacklist. Returning 204 lets the client clear its localStorage
        # token and treat the session as ended.
        head :no_content
      end

      private

      def user_params
        params.permit(:email, :password, :password_confirmation)
      end

      def auth_payload(user)
        {
          token: JsonWebToken.encode(user_id: user.id),
          user: ActiveModelSerializers::SerializableResource.new(user, serializer: UserSerializer).as_json
        }
      end
    end
  end
end
