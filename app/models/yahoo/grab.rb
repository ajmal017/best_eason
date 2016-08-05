Dir.glob(File.dirname(__FILE__).concat("/strategy/*.rb")).each{ |file| require file }
module Yahoo
  class Grab
    def self.get(stocks)
      return Yahoo::Strategy::Typhoeus.new(stocks).run if stocks.length > 1
      sample_stock = stocks.first
      if sample_stock.retry_times >= 3
        Yahoo::Strategy::Finance.new(sample_stock).run 
      else
        Yahoo::Strategy::Yql.new(sample_stock).run
      end
    end
  end
end
