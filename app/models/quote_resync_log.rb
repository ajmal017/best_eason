# 新版XIGNITE数据源不在使用此MODEL
class QuoteResyncLog < ActiveRecord::Base

  # 类型
  CATEGORY = {
    create: 0,
    update: 1,
    redo: 2
  }
  
  scope :by_base_id, -> (base_id) { where(base_id: base_id) }
  scope :not_kline, -> { where(kline: false) }

end
