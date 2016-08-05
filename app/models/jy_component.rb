# 概念板块列表
class JyComponent < ActiveRecord::Base
  # 1正常 2终止
  default_scope { where(flag: 1) }

  has_many :stock_components, foreign_key: :cs_code, primary_key: :l_two_code
  has_many :base_stocks, through: :stock_components

  # 概念板块
  CONCEPT = 10
  # 地区板块
  AREA = 20
  # 行业板块
  INDUSTRY = 30

  scope :concept, -> { where(l_one_code: CONCEPT) }
  scope :area, -> { where(l_one_code: AREA) }
  scope :industry, -> { where(l_one_code: INDUSTRY) }
end
