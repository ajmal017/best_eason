class Mobile::Account::RegistrationsController < Mobile::ApplicationController
  layout 'mobile/accounts'
  before_filter :authenticate_user!, only: [:info, :update_info]
  def new
    @page_title = "注册账号"
    @user = User.new    
  end

  def create
    @page_title = "注册账号"
    @user = User.new(user_params.merge(channel_code: cookies[:c]))
    flag = true
    if !Sms.verifty(user_params[:mobile], user_params[:captcha])
      @user.errors.add(:captcha, '验证码错误')
      flag = false
    elsif User.exists?(mobile: user_params[:mobile])
      @user.errors.add(:mobile, '账户已存在, 请登录')
      flag = false
    else
      flag = @user.save
    end
    if flag
      sign_in!(@user)
      redirect_to mobile_link(info_mobile_account_registrations_path)
    else
      @message = @user.errors.messages.values.flatten.first
      @user = User.new(user_params)
      render action: :new and return      
    end
  end

  def info
    @page_title = '完善信息'
    @provinces, @cities = CityInit.get_provinces
    @user_cities = CityInit.get_cities_by_province_code(current_user.province)
  end

  def update_info
    @page_title = '完善信息'
    if current_user.update(params[:user].permit(:username, :gender, :province, :city))
      redirect_back_to(cookies[:return_to], mobile_link(mobile_root_path))
      destroy_return_to
    else
      info
      @message = current_user.errors.messages.values.flatten.first
      render 'info'
    end
  end

  def exists
    exists = User.exists?(mobile: params[:mobile])
    render json: {status: exists, message: exists ? '账户已存在, 请登录' : ''}
  end

  def fetch_cities
    @cities = CityInit.get_cities_by_province_code(params[:province_id])
    respond_to do |format|
      format.js
      format.json { render json: { cities: @cities.map(&:name)}, callback: params[:callback], content_type: 'application/javascript' }
    end
  end
private
  def user_params
    params[:user].permit(:mobile, :password, :captcha)
  end
end
