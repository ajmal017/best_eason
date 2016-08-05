#OmniAuth.config.add_camelization('qq_bind', 'QQConnect')
#OmniAuth.config.add_camelization('wechat_bind', 'Wechat')
#OmniAuth.config.add_camelization('weibo_bind', 'Weibo')

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :wechat, Setting.wechat.key, Setting.wechat.secret,
    authorize_params: {
      redirect_uri: "#{Setting.host}/auth/wechat/callback"
    }
  provider :weibo, Setting.weibo.key, Setting.weibo.secret,
    authorize_params: {
      redirect_uri: "#{Setting.host}/auth/weibo/callback"
    }
  provider :qq, Setting.qq.key, Setting.qq.secret,
    authorize_params: {
      redirect_uri: "#{Setting.host}/auth/qq/callback"
    }

  #provider :wechat_bind, Setting.wechat.key, Setting.wechat.secret,
    #authorize_params: {
      #redirect_uri: "#{Setting.host}/auth/wechat_bind/callback"
    #}
  #provider :weibo_bind, Setting.weibo.key, Setting.weibo.secret,
    #authorize_params: {
      #redirect_uri: "#{Setting.host}/auth/weibo_bind/callback"
    #}
  #provider :qq_bind, Setting.qq.key, Setting.qq.secret,
    #authorize_params: {
      #redirect_uri: "#{Setting.host}/auth/qq_bind/callback"
    #}
end
