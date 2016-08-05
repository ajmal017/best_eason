module Spider

  class Crawler

    def initialize(url)
      @response = Typhoeus::Request.get(
        url, 
        :headers       => {"Content-Type" => "text/html", "Accept"=>"application/xml;q=0.9,*/*;q=0.8", "User-Agent"=>"Mozilla/5.0 (X11; Linux x86_64; rv:2.0.1) Gecko/20100101 Firefox/4.0.1","Referer"=>"http://www.baidu.com"},
        :timeout       => 3000 # milliseconds
      )
    end

    def body
      @response.body
    end

    # Spider::Crawler.run(:sina)
    def self.run(site)
      ("Spider::Sites::" + site.to_s.camelize).constantize.new
    end

  end

end