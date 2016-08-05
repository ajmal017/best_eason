module Yahoo
  class Utils
    include Singleton

    attr_accessor :tickers

    def initialize(file_path="#{Rails.root}/data/new_blank_tickers") 
      @file_path = file_path
      @tickers = load_tickers
    end

    private

    def load_tickers
      tickers = File.readlines(@file_path).map{|x| x.chomp.split(',') }
      Hash[tickers]
    end
  end
end
