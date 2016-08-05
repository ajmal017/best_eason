module Trading

  class Issue
    PROCESSED_COUNTRY = ["USA", "HKG"]
  
    def initialize(issue)
      @issue = issue
    end
  
    # type is 'current' or 'forecast'
    def create_ib_fundamental(xml, type)
      ::IbFundamental.find_or_initialize_by(key).update("#{type}_xml" => xml) if data_valid?
    end
  
    def key
      { 
        symbol: symbol, 
        exchange: exchange 
      }
    end
  
    def symbol
      @issue.xpath("IssueID[@Type='Ticker']").try(:text)
    end
  
    def exchange
      @issue.xpath("Exchange").try(:text)
    end
  
    def exchange_country
      @issue.xpath("Exchange").first["Country"]
    end
  
    def data_valid?
      exchange.present? && symbol.present? && ["USA", "HKG"].include?(exchange_country)
    end
  
    def name
      @issue.xpath("IssueID[@Type='Name']").try(:text)
    end
  end
  
end