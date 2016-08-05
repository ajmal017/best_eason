module Yahoo
  class HistoricalFailLog < ActiveRecord::Base
    self.table_name = 'yahoo_logs'

    belongs_to :stock, class_name: 'BaseStock', foreign_key: 'base_id'
  end
end
