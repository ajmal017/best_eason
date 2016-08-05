class DailyQuote::Cn < ActiveRecord::Base
  include DailyQuote::Commonable

  self.table_name = "historical_quote_cns"
end
