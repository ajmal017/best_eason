module Weixin
  class AccessToken
    include Singleton
    
    def initialize()
      @appid = Setting.weixin.app_id
      @secret = Setting.weixin.app_secret
      @access_token, @expire_at = get_access_token
    end

    def token
      if expired?
        @access_token, @expire_at = get_access_token
      end
      @access_token
    end

    private
    def expired?
      Time.now >= @expire_at - 60
    end

    def get_access_token
      get_token_params = {grant_type: 'client_credential', appid: @appid, secret: @secret}
      response = Remote::Base.get wx_token_url, get_token_params
      results = JSON.parse(response.body[:result]) rescue nil
      raise "fetch access_token error!" if results["errcode"].present? && results["errcode"] != 0
      return results["access_token"], Time.now + results["expires_in"].to_i
    end

    def wx_token_url
      Client::BASE_URL + "/token"
    end
  end
end
