module Authenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  private

  def authenticate_user!
    token = bearer_token
    return render_unauthorized("Missing bearer token") if token.blank?

    payload = JsonWebToken.decode(token)
    @current_user = User.find_by(id: payload[:user_id])
    render_unauthorized("User no longer exists") if @current_user.nil?
  rescue JWT::ExpiredSignature
    render_unauthorized("Token expired")
  rescue JWT::DecodeError
    render_unauthorized("Invalid token")
  end

  def current_user
    @current_user
  end

  def bearer_token
    header = request.headers["Authorization"].to_s
    header.start_with?("Bearer ") ? header.split(" ", 2).last : nil
  end

  def render_unauthorized(message)
    render json: { error: message }, status: :unauthorized
  end
end
