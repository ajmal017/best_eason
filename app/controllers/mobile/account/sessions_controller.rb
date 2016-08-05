class Mobile::Account::SessionsController < Mobile::ApplicationController
  layout 'mobile/accounts'
  def new
    if current_user
     redirect_back_to(params[:return_to], mobile_link(mobile_root_path))
    else
      @page_title = "登录"
      @user = User.new
    end
  end

  def create
    @page_title = "登录"
    @user = User.check_login?(params[:user][:mobile], params[:user][:password])
    sign_in!(@user) if @user
    
    respond_to do |format|
      if @user
        format.html { redirect_back_to(cookies[:return_to], mobile_link(mobile_root_path)) }
        destroy_return_to
      else
        @message = '错误的用户名或密码'
        format.html { @user=User.new(mobile: params[:user][:mobile]); render action: :new }
      end

      format.js
    end
  end
end
