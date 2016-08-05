class StockIndustry < ActiveRecord::Base
  belongs_to :base_stock
  belongs_to :jy_industry, foreign_key: :industry, primary_key: :code
end
