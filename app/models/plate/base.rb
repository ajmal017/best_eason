module Plate
  class Base < ActiveRecord::Base
    self.table_name = "plates"
    
    STATUSES = %w(new active inactive)

    has_many :plate_stocks, -> { where("plate_stocks.status = 'active'")}, foreign_key: :plate_id, dependent: :destroy
    has_many :base_stocks, through: :plate_stocks

    scope :cn, -> { where(market: :cn) }
    scope :us, -> { where(market: :us) }
    scope :hk, -> { where(market: :hk) }

  end
end
