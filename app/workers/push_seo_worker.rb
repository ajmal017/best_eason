require 'net/http'
class PushSeoWorker
  @queue = :push_seo
  
  def self.perform(seo_urls)
    %w[baidu google].each { |t| send("#{t}_push_url", seo_urls) }
  end

  def self.baidu_push_url(seo_urls)
    uri = URI.parse("http://data.zz.baidu.com/urls?site=www.caishuo.com&token=#{Setting.baidu_token}")
    req = Net::HTTP::Post.new(uri.request_uri)
    req.body = seo_urls.map{|url| Setting.host + url }.join("\n")
    req.content_type = 'text/plain'
    res = Net::HTTP.start(uri.hostname, uri.port) { |http| http.request(req) }
    result = res.body
  ensure
    $seo_logger.info("PUSH BAIDU SEO URL --> urls: #{seo_urls.join(',')}, result: #{result}")
  end

  def self.google_push_url(seo_urls)
    result = "not do push task"
  ensure
    $seo_logger.info("PUSH GOOGLE SEO URL --> urls: #{seo_urls.join(',')}, result: #{result}")
  end
end
