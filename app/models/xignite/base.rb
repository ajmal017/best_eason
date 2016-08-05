module Xignite
  class Base
    
    attr_reader :body

    def initialize(method, url, params = {}, body = {}, headers = {})
      options = {
        method: method, 
        timeout: 30000,
        proxy: Setting.proxy.url
      }
      
      options.merge!(params: params) if params.present?
      options.merge!(body: body.to_json) if body.present?
      
      start_time = Time.now

      request = ::Typhoeus::Request.new(url, options)
      
      request.on_complete do |response|
        
        Rails.logger.info("xignite sync time: #{Time.now - start_time}")
        
        @body = $json.decode(response.body) rescue ""
      end

      hydra = Typhoeus::Hydra.hydra
      hydra.queue(request)
      hydra.run
    end

    # 访问接口
    def self.get(url, params = {}, opts = {})
      new(:get, url, params, {}, opts)
    end

    def self.head(url, params = {}, opts = {})
      new(:get, url, params, {}, opts)
    end

    def self.post(url, params = {}, body = {}, opts = {})
      new(:post, url, params, body, opts)
    end
  end
end
