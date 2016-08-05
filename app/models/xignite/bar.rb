module Xignite
  module Bar
    class Base

      URL = "http://globalquotes.xignite.com/v3/xGlobalQuotes.json/GetBars"

      def initialize(symbol, start_date, end_date, period = 1)
        @symbol = symbol
        @start_date = start_date
        @end_date = end_date
        @period = period
      end

      def sync
        @response = Xignite::Base.get(request_url)
        @response.body['Bars'].map do |stock|
          Quote.new(stock.transform_keys!{|x| x.to_s.underscore }).to_array
        end
      rescue Exception => e
        []
      end

      def request_url
        URL + "?IdentifierType=Symbol&Identifier=#{@symbol}&StartTime=#{start_time}&EndTime=#{end_time}&Precision=Minutes&Period=#{@period}&_fields=Bars,Bars.EndDate,Bars.EndTime,Bars.UTCOffset,Bars.Close,Bars.Volume&_token=#{Setting.xignite.token}"
      end

      def start_time
        URI.encode(@start_date.strftime('%m/%d/%Y') + " 09:30 AM")
      end

      def end_time
        URI.encode(@end_date.strftime('%m/%d/%Y') + " 05:00 PM")
      end

    end

    class Quote
      FIELDS = %w(end_date end_time utc_offset close volume)

      def initialize(opts = {})
        FIELDS.each do |attribute|
          instance_variable_set("@#{attribute}", opts[attribute])
        end
      end

      def to_array
        [trade_time, @close, @volume]
      end

      def trade_time
        Time.strptime([@end_date, @end_time, '+0000'].join(' '), "%m/%d/%Y %I:%M:%S %p %z").to_i * 1000
      end

    end

  end
end
