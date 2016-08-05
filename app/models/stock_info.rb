class StockInfo < ActiveRecord::Base
  def truncated_desc
    description.present? ? description.truncate(20) : profession.to_s.truncate(20)
  end
end
