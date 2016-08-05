module ProviderAccount
  extend ActiveSupport::Concern

  PROVIDER = %w[ wechat weibo qq ]
  PROVIDER_MAP = PROVIDER.zip(%w[ WX WB QQ ]).to_h
  PROVIDER_ZH = PROVIDER.zip(%w[ 微信 微博 QQ ]).to_h

  def show_completion?
    mobile.blank? && encrypted_password.blank?
  end

  def is_provider_user?
    mobile.blank? && email.blank?
  end

  def can_remove_bind?
    !(is_provider_user? && user_providers.count <= 1)
  end

  def provider_for_api
    PROVIDER.reduce({}) do |p,v|
      p[v] = self.send("#{v}_provider_actived").try(:nick_name)
      p
    end
  end


  included do
    require 'net/http'
    attr_accessor :is_new
    PROVIDER.each do |p|
      has_many :user_providers, -> { actived }
      has_one "#{p}_provider".to_sym, -> { where(provider: PROVIDER_MAP[p]) }, class_name: "UserProvider", dependent: :destroy
      has_one "#{p}_provider_actived".to_sym, -> { where(provider: PROVIDER_MAP[p]).actived }, class_name: "UserProvider", dependent: :destroy
    end

  end

  module ClassMethods

    def verify_access_token(provider, uid, access_token)
      send("verify_by_#{provider}", access_token, uid)
    rescue
      false
    end

    def bind_provider_user(current_user, provider, uid, user_info)
      error, msg = false, nil

      error = true and msg = "不存在登录用户" and return unless current_user.present?

      up = UserProvider.actived.find_by(provider_id: uid, provider: provider_abbr(provider))

      # 微信兼容之前provider_id存了open_id的用户, 并且更新provider_id 为 union_id
      if provider_abbr(provider) == "WX" && up.blank? && user_info[:openid].present?
        up = UserProvider.actived.find_by(provider_id: user_info[:openid], provider: provider_abbr(provider))
        up.update_attributes!(provider_id: uid, ext: user_info.to_json) if up.present?
      end

      if up.present?
        error = true
        msg = up.provider_id == uid ? "该#{PROVIDER_ZH[provider]}已与您的财说账户绑定" : "您的#{PROVIDER_ZH[provider]}已绑定过其他财说账号，请解绑后再继续操作"
        return
      end
      error = true and msg = "当前用户已绑定#{PROVIDER_ZH[provider]}帐号" and return if current_user.send("#{provider}_provider_actived").present?

      up = UserProvider.new(provider_id: uid, provider: provider_abbr(provider), ext: user_info.to_json)
      current_user.send("#{provider}_provider=", up)

      current_user.save!
    ensure
      return {error: error, msg: msg}
    end

    # RETURN
    # user: 用户 is_new: 是否为新用户
    def make_provider_user(provider, uid, user_info)
      return [nil, false] unless PROVIDER.include?(provider)

      up = UserProvider.actived.find_by(provider_id: uid, provider: provider_abbr(provider))

      # 微信兼容之前provider_id存了open_id的用户, 并且更新provider_id 为 union_id
      if provider_abbr(provider) == "WX" && up.blank? && user_info[:openid].present?
        up = UserProvider.actived.find_by(provider_id: user_info[:openid], provider: provider_abbr(provider))
        up.update_attributes!(provider_id: uid, ext: user_info.to_json) if up.present?
      end

      return [up.user, false] if up.present?

      user = User.new
      user = self.send("fill_user_by_#{provider}", user, user_info)

      up = UserProvider.new(provider_id: uid, provider: provider_abbr(provider), ext: user_info.to_json)
      user.send("#{provider}_provider=", up)

      user.save!

      [user, true]
    end

    def fill_user_by_weibo(user, user_info)
      user.username = user_info[:nickname].full_width_tr if user_info[:nickname].present?
      user.username ||= user_info[:name].full_width_tr
      user.remote_avatar_url = user_info[:image] if user_info[:image].present?
      user.channel_code = user_info[:channel_code]
      user
    end

    def fill_user_by_wechat(user, user_info)
      user.username = user_info[:nickname].full_width_tr
      user.remote_avatar_url = user_info[:headimgurl] if user_info[:headimgurl].present?
      user.channel_code = user_info[:channel_code]
      user
    end

    def fill_user_by_qq(user, user_info)
      user.username = user_info[:nickname].full_width_tr if user_info[:nickname].present?
      user.username ||= user_info[:name].full_width_tr
      user.remote_avatar_url = user_info[:image] if user_info[:image].present?
      user.channel_code = user_info[:channel_code]
      user
    end

    def verify_by_weibo(token, uid)
      url = "https://api.weibo.com/oauth2/get_token_info"
      h_post(url, access_token: token)["uid"].to_s == uid.to_s
    end

    def verify_by_wechat(token, uid)
      url = "https://api.weixin.qq.com/sns/userinfo?access_token=#{token}&openid=#{uid}"
      data = h_get(url)
      data["unionid"] == uid
    end

    def verify_by_qq(token, uid)
      url = "https://graph.qq.com/oauth2.0/me"
      h_post(url, access_token: token)["openid"] == uid
    end

    def h_post(url, params={})
      uri = URI(url)
      res = Net::HTTP.post_form(uri, params)
      body = /{.*}/.match(res.body)[0]
      result = JSON.parse(body)
      result
    ensure
      $api_logger.info("POST URL: #{url}, PARAMS: #{params}, RESULT: #{result}")
    end

    def h_get(url)
      uri = URI(url)
      res = Net::HTTP.get(uri)
      result = JSON.parse(res)
      result
    ensure
      $api_logger.info("GET URL: #{url}, RESULT: #{result}")
    end

    def provider_abbr(provider)
      PROVIDER_MAP[provider]
    end

  end
end
