class Internal::BaseController < ActionController::Base
  before_action :auth_secret_key

  private
  def auth_secret_key
    secret = request.headers["Authorization"].to_s
    render json: {status: false} and return unless Setting.internal_api.secret == secret
  end
end