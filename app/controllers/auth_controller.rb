class AuthController < ApplicationController
  layout false

  # 第三方授权后跳转到这里
  def callback
    raise "未知来源" unless User::PROVIDER.include?(params[:provider])

    @is_bind = false

    # 绑定第三方帐号
    if current_user.present?

      @is_bind = true
      @bind_result = User.bind_provider_user(current_user, provider, uid, user_info)

    # 第三方登录或注册
    else

      @user, @is_new = User.make_provider_user(provider, uid, user_info.merge(channel_code: cookies[:c]))
      sign_in!(@user)

    end

  end

  # 解除第三方帐号绑定
  def remove_bind
    raise "未知来源" unless (User::PROVIDER).include?(params[:provider])

    if current_user.can_remove_bind? && current_user.send("#{params[:provider]}_provider_actived").present?
      current_user.send("#{params[:provider]}_provider_actived").destroy
    end

    redirect_to bind_setting_index_path
  end

  private

    def user_info
      omniauth_auth[:info]
    end

    def uid
      omniauth_auth[:uid]
    end

    def provider
      omniauth_auth[:provider]
    end

    def omniauth_auth
      @omniauth_auth ||= request.env["omniauth.auth"].to_hash.with_indifferent_access
    end

end
