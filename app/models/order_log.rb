class OrderLog < ActiveRecord::Base
  validates :ib_order_id, presence: true
  belongs_to :base_stock
  belongs_to :order
end
