class PlateStock < ActiveRecord::Base
  belongs_to :plate, class_name: Plate::Base, counter_cache: :stocks_count
  belongs_to :base_stock

  validates :plate_id, presence: true, uniqueness: {scope: :base_stock_id}
  validates :base_stock_id, presence: true

  scope :active, -> { where(status: 'active') }
end
