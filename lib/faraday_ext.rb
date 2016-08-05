require 'typhoeus/adapters/faraday'
module Remote
  class Base
    attr_accessor :response

    # Http接口请求初始化类
    # 
    # === 参数
    #
    # * +method+ -请求方法
    # * +url+ -请求地址
    # * +params+ -请求参数
    # * +params[:timeout]+ -超时时间
    def initialize(method, url, params = {})
      start_time = Time.now

      conn = Faraday.new(url: url) do |faraday|
        faraday.request :url_encoded
        faraday.adapter :typhoeus
        faraday.proxy params[:proxy] if params[:proxy]
      end

      conn.options[:timeout] = 60
      conn.headers[:user_agent] = "Mozilla/5.0 (X11; Linux x86_64; rv:2.0.1) Gecko/20100101 Firefox/4.0.1"
      conn.headers['Content-Type'] = "application/json"
      conn.headers['Accept'] = "application/json;charset=utf-8"

      @response = conn.send(method, url, params)

      $faraday_logger.info("more than one second url: #{url} time: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}") if (Time.now - start_time) >= 1
    rescue Faraday::Error::TimeoutError
      $faraday_logger.info("timeouted url: #{url} time:#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}") if $faraday_logger.present?
    end

    ##########接口访问###########
    def self.get(url, params = {})
      Base.new(:get, url, params)
    end

    def self.head(url, params = {})
      Base.new(:head, url, params)
    end

    def self.post(url, params = {})
      Base.new(:post, url, params)
    end

    def self.put(url, params = {})
      Base.new(:put, url, params)
    end

    def self.delete(url, params = {})
      Base.new(:delete, url, params)
    end

    ###########状态判断###########
    # 是否成功
    def success?
      @response.success?
    end

    # 是否单条数据
    def single?
      @json.present? && @json.is_a?(Hash)
    end

    # 取返回状态
    def status
      @response.code
    end

    # 取返回body
    def body
      @response.body
    end

    def id
      @json['id'] rescue nil
    end
  end

  module Tools

    class User

    end

    class Historical
      BASE_URL = "http://query.yahooapis.com/v1/public/yql?"

      def self.sync(symbols, start_date, end_date, fields = true)
        symbols = symbols.is_a?(String) ? [symbols].to_s : symbols.pluck(:ticker).to_s
        url = request_url(symbols[1..-2], start_date, end_date, fields)
        r = Remote::Base.get(url, proxy: Setting.proxy.url)
        body = $json.decode(r.body)
        [body['query']['results']['quote'], r.try(:success?)]
      rescue
        $finance_logger.info("Yahoo Historical Synced Error#####RequestUrl: #{url}, ResponseBody: #{r}")
        [[], false]
      end

      def self.request_url(symbols, start_date, end_date, fields)
        fields = fields ? "Symbol,Date, Adj_Close" : "*"
        url = "q=select #{fields} from yahoo.finance.historicaldata where symbol" 
        url << " in (" + symbols + ") " 
        url << 'and startDate = "' 
        url << start_date.to_date.to_s(:db)
        url << '" and endDate = "'
        url << end_date.to_s(:db)
        url << '"&format=json&env=store://datatables.org/alltableswithkeys&callback='
        BASE_URL + URI.encode(url)
      end

    end

    class RealTime
      def self.get(url)
        start_at = Time.now
        response = Remote::Base.get(url, proxy: Setting.proxy.url)
        $rt_logger.info("Download抓取时间: #{Time.now - start_at}, #{url}")
        response
      end
    end

  end
end
