class StockComponent < ActiveRecord::Base
  belongs_to :jy_component, foreign_key: :cs_code, primary_key: :l_two_code
  belongs_to :base_stock
end
