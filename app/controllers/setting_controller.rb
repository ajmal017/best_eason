class SettingController < ApplicationController

  before_filter :authenticate_user!

  before_action :load_counter, only: [:index, :password]

  def index
    @provinces, @cities = CityInit.get_provinces
    @user_cities = CityInit.get_cities_by_province_code(current_user.province)
  end

  def create
    @ret = current_user.update(user_params)
  end

  def avatar
    @page_title = "个人资料修改-头像设置"
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

  def update_email
    @current_password = params[:user][:password]
    if @current_password.present? && @valid_ret = current_user.valid_password?(@current_password)
      current_user.update(email: params[:user][:email]) && current_user.update_column(:email, params[:user][:email])
    end
  end

  def password
    @page_title = "个人资料修改-修改密码"
  end

  def profile
    @page_title = '个人资料修改-个人资料'
    @to = params[:to]
    @profile = current_user.profile || current_user.create_profile
    @provinces, @cities = CityInit.get_provinces
    @user_cities = CityInit.get_cities_by_province_code(current_user.province)
  end

  def update_base_profile
    @ret = current_user.update(base_profile_params)
    render :update_profile
  end

  def update_profile
    @ret = current_user.profile.update_profile(profile_params)
  end

  def mobile
    @page_title = "个人资料修改-绑定手机号"
  end

  def bind
    @page_title = "个人资料修改-帐号绑定"
  end

  def check_bind_email
    @page_title = "个人资料修改-查收邮件"
  end

  def hongbao
    @page_title = '财说红包'
    @start_time = Time.parse('2015-04-13 00:00:00')
    @title, @length = if current_user.created_at < @start_time
      ['老用户', 30]
    else
      ['新人', current_user.invite_code.try(:size) == 4 ? 30 : 15]
    end
    first_bind = current_user.trading_accounts.binded.by_markets(:us, :hk).map(&:created_at).compact.sort.first
    @template_name = if first_bind
      @trading_since = current_user.trading_accounts.binded.by_markets(:us, :hk).map(&:trading_since).compact.sort.first
      if @trading_since
        'actived'
      else
        first_bind < @start_time ? 'bind' : 'success'
      end
    else
      'unbind'
    end
    current_user.counter.try(:set_hongbao_zero)
  end

  def invite_code
    current_user.update(invite_code: params[:user][:invite_code])
    redirect_to action: :hongbao
  end

  private

  def user_params
    params.require(:user).permit(:username, :province, :city, :gender, :password, :password_confirmation, :reset_password_token)
  end

  def base_profile_params
    if params[:user].present? and params[:user][:profile_attributes].present?
      params[:user][:profile_attributes][:id] = current_user.profile.id
    end
    params[:user][:profile_attributes][:id] = current_user.profile.id
    params.require(:user).permit(:username, :headline, :province, :city, :gender, profile_attributes: [:id, :intro])
  end

  def profile_params
    return {taggings_attributes: {}} if params[:from] == "ability" and params[:profile].blank?
    params[:profile][:taggings_attributes] = taggings_attributes if params[:from] == "ability" and params[:profile][:taggings_attributes].present?
    params.require(:profile).permit(:intro, :biography, :duration, orientations: Profile::ORIENTATION.keys, concerns: Profile::CONCERN.keys, taggings_attributes: [:tag_id, :taggable_id, :taggable_type])
  end

  def taggings_attributes
    params[:profile][:taggings_attributes].transform_values { |x| x.merge(taggable_id: current_user.profile.id, taggable_type: "Profile") }
  end

  def load_counter
    @counter = Counter.find_by(user_id: current_user.id)
  end
end
