class OrderStockShare < ActiveRecord::Base
  belongs_to :order, foreign_key: 'instance_id', primary_key: 'instance_id'
  belongs_to :base_stock

  validates :instance_id, presence: true
  validates :base_stock_id, presence: true
  validates :shares, presence: true
  
end