class Open::BaseController < ActionController::Base
  before_action :auth_access_token

  private
  def auth_access_token
    token = params[:access_token].to_s
    unless Setting.cs_open.tokens.include?(token)
      render json: {status: 0, data: [], error: {code:  "10001", msg: "Token验证失败"}} and return
    end
  end
end