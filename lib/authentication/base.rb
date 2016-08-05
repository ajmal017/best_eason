module Authentication::Base

  def self.included(base)
    base.send :helper_method, :current_user, :authorized?, :user_signed_in?
  end

  protected

  # base
  def current_user
    @current_user ||= (login_from_session || login_from_cookie || login_from_basic_auth || login_from_mobile_cookie)
  end

  def current_user=(user)
    sign_login_flag!(user.id)
    @current_user = user
  end

  def current_user_id
    @current_user.try(:id)
  end

  # authorized
  def authorized?
    @current_user
  end
  
  alias_method :user_signed_in?, :authorized?

  def sign_in!(user)
    raise Authentication::UserBlocked if user.blocked?
    self.current_user = user
    # return unless request
    user.last_sign_in_at = Time.now
    user.last_sign_in_ip = request.remote_ip
    user.save(validate: false)
  end

  def sign_out!
    #reset_session
    session.delete(:current_user_id) && session.delete(:last_request_at) rescue reset_session
    reset_logined_cookie
    cookies.delete(:login_token, domain: :all)
  end

  # Remember Token
  def remember_token!
    cookies[:login_token] = {value: "#{Authentication::BCrypt.encrypt(@current_user.created_at)};#{@current_user.id}",
      expires: 3.hours.from_now, domain: :all, httponly: true}
  end

  # Filter
  def access_denied
    unless @current_user
      if request.xhr?
        render js: "openLoginDialog();"
      else
        redirect_to(auth_url) and return 
      end
    end
  end

  def auth_url
    if is_mobile?
      return_url("http://#{$mobile_domain}/login")
    else
      return_url("#{Setting.host}/login")
    end
  end

  alias_method :authenticate_user!, :access_denied

  # url
  def return_url(url, return_to=nil)
    target_url = return_to||request.url
    cookies[:return_to] = {value: target_url, expires: 1.day.from_now}
    "#{url}?return_to=#{CGI.escape(target_url)}"
  end

  def redirect_back_to(return_to, default=nil)
    redirect_to((return_to and CGI.unescape(return_to)) || default || default_redirect_url)
  end

  def default_redirect_url
    '/home'
  end

  private
  
  def sign_login_flag!(user_id)
    session[:current_user_id] = user_id
    session[:last_request_at] = Time.now.to_s(:full)
    cookies[:logined] = { value: true, domain: Setting.domain }
    cookies[:last_request_at] = {value: Time.now.utc.to_i, domain: Setting.domain }
  end
  
  # login
  def login_from_session
    if session[:current_user_id] && session[:last_request_at] > 3.hours.ago
      self.current_user = (User.find(session[:current_user_id]) rescue nil)
    else
      reset_logined_cookie
      return
    end
  rescue
    reset_session
  end

  def login_from_cookie
    return unless cookies[:login_token]
    encrypted_token, user_id = cookies[:login_token].split(';')
    user = User.find_by_id(user_id.to_i)
    if user && Authentication::BCrypt.decrypt?(user.created_at, encrypted_token)
      self.current_user = user
    else
      cookies.delete :login_token
      return nil
    end
  end
  
  def login_from_mobile_cookie
    return nil unless cookies["SESS"]

    token = ApiToken.where(access_token: cookies["SESS"], sn_code: cookies["X-SN-Code"]).first
    
    # 如果token存在并且没有过期
    if token && !token.expired?
      # 如果临近过期时间，推迟过期时间
      token.refresh_expires_at! if token.expires_at - Time.now <= 3.days
      token.user
    else
      nil
    end
  end

  def login_from_basic_auth
    authenticate_with_http_basic do |login, password|
      user = User.check_login?(login, password)
      self.current_user = user if user.present?
    end
  end

  def reset_logined_cookie
    cookies.delete(:logined, domain: Setting.domain)
    cookies.delete(:last_request_at, domain: Setting.domain)
  end

end
