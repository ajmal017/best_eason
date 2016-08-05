class Ajax::UsersController < Ajax::ApplicationController
  skip_before_action :require_xhr?, only: [:save_avatar, :crop_avatar, :setting_crop]

  before_filter :authenticate_user!, only: [:property_datas, :sell_basket, :following_stocks, :check_mobile_binded, :query]
  
  def bubble
    user = User.find(params[:id])
    abilities = user.profile.try(:tags) || []
    datas = {
        user: {
          avator: user.avatar_url(:large),
          link: "/p/#{user.id}",
          msglink: current_user ? messages_path(user_id: user.id) : "",
          username: user.username,
          headline: user.headline,
          gender: user.gender_name,
          city: user.city,
          intro: user.profile.try(:intro),
          ability: abilities.map(&:name)
        },
        focused: {
          stocks: Follow::Stock.followed_stocks_by(user.id).count,
          baskets: user.baskets.normal.finished.count,
          people: user.pretty_fans_count
        },
        isFocused: user.followed_by?(current_user) ? 1: 0
      }
    render json: datas
  end
  
  def query
    users = current_user.query_by_term(params[:q])
    render json: users
  end

  def save_avatar 
    if params[:id].to_i == current_user.id
      if current_user.temp_image
        current_user.temp_image.update(image: params[:user][:avatar])
      else
        current_user.create_temp_image(image: params[:user][:avatar], user_id: current_user.id)
      end
    end
  end

  def crop_avatar
    current_user.temp_image.update(upload_user_params)
  end

  def setting_crop
    @ret = current_user.temp_image.update(upload_user_params)
    current_user.update(avatar: current_user.temp_image.image.large) if @ret
  end

  def check_invite_code
    respond_to do |format|
      format.json do 
        render json: InvitationCode.code_valid?(params[:user][:invite_code])
      end
    end
  end

  def check_email
    respond_to do |format|
      format.json do
        render json: !User.where('lower(email) = ?', params[:user][:email].downcase).exists?
      end
    end
  end

  def check_email_exists
    respond_to do |format|
      format.json do
        render json: User.where('lower(email) = ?', params[:user][:email].downcase).exists?
      end
    end
  end

  def check_username
    respond_to do |format|
      format.json do
        render json: User.username_avaliable?(params[:user][:username], current_user.try(:id))
      end
    end
  end

  def check_password
    respond_to do |format|
      format.json do 
        render json: current_user.valid_password?(params[:user][:current_password] || params[:user][:password])
      end
    end
  end

  def logined
    respond_to do |format|
      format.json do
        render json: {logined: current_user.present?}
      end
    end
  end

  def check_captcha
    respond_to do |format|
      format.json do
        render json: valid_captcha?(params[:user][:captcha])
      end  
    end
  end

  def check_email_or_name
    render json: User.exists?(email: params[:email]) || User.exists?(username: params[:username])
  end

  def follow
    @follow = Follow::User.add(current_user, params[:id])
  end

  def unfollow
    @ret = Follow::User.remove(current_user, params[:id])
  end

  def toggle_follow
    user = User.find(params[:id])
    follow_status = current_user.follow_user(user)
    render json: {status: true, followed: follow_status}
  end
  
  def following_stocks
    trading_areas = Exchange::Util.get_trading_areas.map(&:to_s)
    usd_rates = Currency.all_to_usd
    @follows = Follow::Stock.by_user(current_user.id).pluck(:followable_id, :id).to_h
    stock_infos = ::MD::RS::Stock.where(:base_stock_id.in => @follows.map(&:first), :market.in => trading_areas)
                    .map(&:pretty_json).map{|s| s.merge(follow_id: @follows[s[:base_stock_id.to_s]], usd_rate: usd_rates[s[:currency.to_s]]) }
    render json: stock_infos
  end

  def unread_notifications
    @notifications = current_user.unread_notifications.limit(3)
  end

  def property_datas
    begin_date = Date.parse(params[:begin_date]) # todo
    day_properties = UserDayProperty.datas_by(current_user, begin_date)
  end

  def check_mobile_exists
    render json: !User.exists?(mobile: params[:user][:mobile])
  end

  def check_mobile_register
    render json: User.exists?(mobile: params[:user][:mobile])
  end

  def check_mobile_or_email
    render json: User.exists?(mobile: params[:user][:account]) || User.exists?(email: params[:user][:account])
  end

  # 检查手机号是否绑定
  def check_mobile_binded
    render json: current_user.mobile.present?
  end

  # 需要登录
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

  def bind_or_update_mobile
    mobile, captcha = params[:user][:mobile], params[:user][:code]

    @result = false
    @msg =
      if User.find_by(mobile: mobile).present?
        "手机号已被绑定!"
      elsif !Sms.verifty(mobile, captcha)
        Sms.error_info(mobile)
      elsif current_user.update!(mobile: mobile)
        @result = true
        "绑定成功!"
      else
        "绑定失败!"
      end
    render "bind_mobile"
  end

  def bind_mobile_and_password
    mobile, captcha, password = params[:user][:mobile], params[:user][:code], params[:user][:password]
    @result = false
    @msg =
      if User.find_by(mobile: mobile).present?
        "手机号已被绑定!"
      elsif !Sms.verifty(mobile, captcha)
        Sms.error_info(mobile)
      elsif current_user.update!(mobile: mobile, password: password)
        @result = true
        "绑定成功!"
      else
        "绑定失败!"
      end
    render "bind_mobile"
  end

  def bind_mobile
    mobile, code = params[:user][:mobile], params[:user][:code]

    @result = false
    @msg =
      if current_user.mobile.present?
        "该用户已绑定手机号!"
      elsif User.find_by(mobile: mobile).present?
        "手机号已被绑定!"
      elsif !Sms.verifty(mobile, code)
        Sms.error_info(mobile)
      elsif current_user.update!(mobile: mobile)
        @result = true
        "绑定成功!"
      else
        "绑定失败!"
      end
  end

  def bind_mobile_account
    mobile, code = params[:user][:mobile], params[:user][:code]

    @result = false
    @msg =
      if current_user.mobile.present?
        "该用户已绑定手机号!"
      elsif User.find_by(mobile: mobile).present?
        "手机号已被绑定!"
      elsif !Sms.verifty(mobile, code)
        Sms.error_info(mobile)
      elsif current_user.update!(mobile: mobile)
        @result = true
        "绑定成功!"
      else
        "绑定失败!"
      end

    render json: {result: @result, msg: @msg}
  end

  def bind_or_update_email
    email = params[:user][:email]

    if (current_user.send_rebind_email(email) rescue false)
      @result = true
      @msg = "已发送重新绑定邮件到新的电子邮箱，请查收"
    else
      @result = false
      @msg = "发送邮件失败"
    end

    render "bind_or_update_email"
  end

  def resend_bind_or_update_email
    email = params[:email]

    if (current_user.send_rebind_email(email) rescue false)
      @result = true
      @msg = "已发送重新绑定邮件到新的电子邮箱，请查收"
    else
      @result = false
      @msg = "发送邮件失败"
    end

    render json: {status: @result, msg: @msg}
  end

  # 主题/个股/现金比例
  # {:cash=>44.74, :basket=>19.75, :stock=>35.51}
  def investment_percent
    #percent_infos = Position.invest_ratio(current_user)
    percent_infos = Position.invest_ratio(current_user)
    render json: percent_infos.map{|type, percents| [type, percents.last.try(:to_f)]}.to_h
  end

  private

  def upload_user_params
    params.require(:user).permit(:crop_x, :crop_y, :crop_w, :crop_h, :crop_t)
  end

end
