class PositionDelta < ActiveRecord::Base
  validates :user_id, presence: true
  validates :base_stock_id, presence: true
  validates :delta, numericality: { only_integer: true }, allow_blank: true
  validates :average_cost, numericality: { greater_than_or_equal_to: 0 }, allow_blank: true
  
  
  belongs_to :user
  belongs_to :base_stock
  
  scope :with_stock, -> ( stock_id ) { where(base_stock_id: stock_id) }
  
  
  def update_delta(delta)
    self.with_lock do
      self.delta = delta
      self.save!
    end
  end
  
  def update_avg_cost(avg_cost)
    self.with_lock do
      self.average_cost = avg_cost.to_d
      self.save!
    end
  end
end
