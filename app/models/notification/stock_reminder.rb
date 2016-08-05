module Notification
  class StockReminder < Base
    include Countable

    def url
    	"/stocks/#{mentionable_id}"
    end
  end
end