class Portfolio < ActiveRecord::Base
  belongs_to :base_stock
  belongs_to :user
  belongs_to :trading_account
  
  # 港股
  scope :with_sehk, -> { where(base_stocks: {exchange: 'SEHK'}) }
  
  # 美股
  scope :with_us, -> { where.not(base_stocks: {exchange: 'SEHK'}) }
  
  # 属于某个用户
  scope :by_user, ->(user_id) { where(user_id: user_id) }

  scope :account_with, ->(account_id) { where(trading_account_id: account_id) }
  
  # 具有stock_id
  scope :stock_with, ->(stock_id) { where(base_stock_id: stock_id) }
  
  #
  scope :by_symbol, ->(symbol) { joins(:base_stock).where("base_stocks.symbol = ? or base_stocks.ib_symbol= ?", symbol, symbol) }

  before_create :set_user

  def allocate
    allocated? ? remove_unallocate : move_shares_to_unallocate
  end

  def remove_unallocate
    Position.account_with(trading_account_id).stock_with(base_stock_id).unallocated.first.try(:destroy)
  end

  def move_shares_to_unallocate
    Position.find_or_initialize_by(instance_id: "unallocate", base_stock_id: base_stock_id, trading_account_id: trading_account_id).update(shares: position.to_i - allocated_shares)
  end

  def allocated_shares
    Position.account_with(trading_account_id).stock_with(base_stock_id).allocated.sum(:shares)
  end

  def allocated?
    position.to_i == allocated_shares
  end
  
  def reconcile(avg_price = nil)
    others_position.reconcile(reconcile_attrs(avg_price))
    force_adjust_position if others_shares_negative?
    destroy_others_position if others_shares_zero?
  end
  
  def others_shares_zero?
    others_position.shares.to_i == 0
  end
  
  def destroy_others_position
    others_position.destroy
  end
  
  def force_adjust_position
    $pms_logger.info("强制调平: others position < 0") if Setting.pms_logger
    portfolio_negative? ? copy_attrs_from_portfolio : adjust_basket_position
    destroy_others_position if others_shares_zero?
  end
  
  def adjust_position(avg_price)
    $pms_logger.info("adjust_position: others position < 0") if Setting.pms_logger
    adjust_basket_position(avg_price)
    destroy_others_position if others_shares_zero?
  end
  
  def copy_attrs_from_portfolio
    others_position.update_others_position(position.to_i, average_cost.to_d)
  end
  
  def reconcile_attrs(avg_price = nil)
    { 
      shares: reconcile_shares,
      average_cost: reconcile_average_cost(avg_price)
    }
  end
  
  def reconcile_shares
    self.position.to_i - basket_shares
  end
  
  def basket_shares
    self.user.basket_shares_of(self.base_stock_id)
  end
  
  def basket_total_cost
    self.user.total_cost(self.base_stock_id)
  end
  
  def reconcile_total_cost
    self.position.to_i * self.average_cost.to_d - basket_total_cost
  end
  
  def reconcile_average_cost(avg_price)
    return avg_price.to_f if avg_price.present?
    reconcile_shares > 0 ? (reconcile_total_cost/reconcile_shares).round(10) : 0
  end
  
  def others_shares_negative?
    others_position.shares.to_i < 0
  end
  
  def portfolio_negative?
    self.position.to_i < 0
  end
  
  def others_position
    Position.find_or_create_by(instance_id: "others", base_stock_id: base_stock_id, trading_account_id: trading_account_id)
  end
  
  def ordered_basket_positions
    basket_positions.order("shares desc")
  end
  
  def adjust_basket_position(avg_price = nil)
    ActiveRecord::Base.transaction do
      sum = 0
      total_sub = 0
      ordered_basket_positions.each_with_index do |p, i|
        if last_position?(i)
          total_sub += p.distribute_and_create_order(sum, avg_price)
        else
          total_sub += p.distribute_and_create_order(nil, avg_price)
          sum += p.subtracted_shares
        end
      end
      $pms_logger.info("所有basket总共减去的股数total_sub=#{total_sub}") if Setting.pms_logger
      update_others_after_distribute(total_sub)
    end
  end
  
  def update_others_after_distribute(total_sub)
    others_position.update_others_shares(total_sub - others_shares.abs)
  end
  
  def others_shares
    others_position.shares.to_i
  end
  
  def basket_positions
    user.basket_positions.stock_id_with(base_stock_id)
  end
  
  def basket_positions_count
    @count || ( @count = basket_positions.count )
  end
  
  def last_position?(index)
    index == basket_positions_count - 1
  end
  
  def reconciled?
    self.position.to_i == allocated_shares
  end

  def set_user 
    self.user_id = self.trading_account.user_id
  end

end
