class Mobile::Account::UsersController < Mobile::ApplicationController
  before_filter :authenticate_user!, except: [:send_sms_code]
  def send_sms_code
    result = false
    msg =
      if params[:mobile].blank? || params[:mobile] !~ /^((\+86)|(86))?\d{11}$/
        "手机号格式有误!"
      # elsif Sms.bind_mobile_count(current_user) > 5
      #   "请求过于频繁!"
      elsif Sms.send(params[:mobile])
        result = true
        "发送成功!"
      else
        "发送失败!"
      end
    render json: {status: result, msg: msg}
  end
end
