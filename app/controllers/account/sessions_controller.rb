class Account::SessionsController < Account::BaseController
  before_filter :remember_email, only: [:create]
  before_filter :check_permission, only: [:new, :create]
  
  skip_before_action :verify_authenticity_token, if: :js_request?

  layout 'application'
  
  def new   
    @page_title = "登录"
    @background_color = "white"
  end

  def create
    @page_title = "登录"
    @user = User.check_login?(params[:user][:email], params[:user][:password])
    
    #remember_token! if params[:remember_me]
    sign_in!(@user) if @user
    
    respond_to do |format|
      if @user
        format.html { redirect_back_to(params[:return_to]||cookies[:return_to]) and destroy_return_to }
      else
        format.html { render action: :new }
      end

      format.js
    end
  end

  def destroy
    sign_out!
    redirect_to "/?from=logout"
  end
    
  private

  def remember_email
    cookies[:email] = { value: params[:user][:email], expires: 1.year.from_now } if params[:remember_me]
  end

  def check_permission
    redirect_to root_path if current_user.present?
  end

  def js_request?
    request.format.js?
  end
end
