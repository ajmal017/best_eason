class DailyQuote::Foreign < ActiveRecord::Base
  include DailyQuote::Commonable

  self.table_name = "historical_quotes"
end
