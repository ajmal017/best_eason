# 聚源行业分类列表
class JyIndustry < ActiveRecord::Base
  
  # 一级行业
  LEVEL_ONE = 1
  # 二级行业
  LEVEL_TWO = 2
  # 三级行业
  LEVEL_THREE = 3
  
  scope :level_one, -> { where(level: LEVEL_ONE) }
  scope :level_two, -> { where(level: LEVEL_TWO) }
  scope :level_three, -> { where(level: LEVEL_THREE) }

  # 该行业下的股票
  def stocks
    BaseStock.joins(:stock_industry).where(stock_industries: {foreign_key => code})
  end
  
  def stock_industries
    StockIndustry.where(foreign_key => code)
  end
  
  FOREIGN_KEYS = {
    1 => :first_industry_code,
    2 => :second_industry_code,
    3 => :industry
  }
  def foreign_key
    FOREIGN_KEYS[level]
  end

end
