module Trading
  
  class UpdatePortfolioHandler
    extend Forwardable
    
    def_delegators :@account, :premote_reconcile_level, :first_portfolio_message?
    def_delegators :@others_position, :others_shares_zero?
    
    include InitHelper
    
    def initialize(options)
      super(options)
      @account = ::TradingAccount.find_by!(broker_no: account_name)
      @stock = ::BaseStock.find_by(ib_id: contract_id) || ::BaseStock.find_by!(ib_symbol: symbol)
      @before_portfolio = ::Portfolio.find_by(key_attrs).position rescue 0
      @others_position = ::Position.find_or_create_by(instance_id: "others", base_stock_id: @stock.id, trading_account_id: @account.id)
    end
    
    def perform
      $pms_logger.info("UpdatePortfolio: 更新前：#{@before_portfolio},更新后：position = #{position.to_i},account_id#{@account.id},symbol=#{symbol}") if Setting.pms_logger
      with_transaction
    end
    
    def with_transaction
      ActiveRecord::Base.transaction do
        log_portfolio_data
        if portfolio_changed?
          $pms_logger.info("UpdatePortfolio: portfolio变化，本次#{position.to_i},account_id=#{@account.id},symbol=#{symbol}") if Setting.pms_logger
          update_portfolio
          destroy_others_position if others_shares_zero?
        end
      end
    end
    
    def update_portfolio
      if first_portfolio_message?
        $pms_logger.info("UpdatePortfolio: 第一次,account_id=#{@account.id},symbol=#{symbol}") if Setting.pms_logger
        update_others_position
      else
        adjust_reconcile_request unless portfolio_eq_position?
      end
    end
    
    def portfolio_eq_position?
      position.to_i == Position.account_with(@account.id).stock_with(@stock.id).allocated.sum(:shares)
    end
    
    def log_portfolio_data
      ::Portfolio.find_or_initialize_by(key_attrs).update_attributes(auxiliary_attrs)
    end
    
    def key_attrs
      {
        base_stock_id: @stock.id, 
        trading_account_id: @account.id
      }
    end
    
    def auxiliary_attrs
      {
        symbol: symbol, 
        position: position.to_i, 
        currency: currency, 
        contract_id: contract_id, 
        market_price: market_price.to_d, 
        market_value: market_value.to_d, 
        average_cost: average_cost.to_d, 
        unrealized_pnl: unrealized_pnl.to_d, 
        realized_pnl: realized_pnl, 
        account_name: account_name,
        updated_by: "updatePortfolio"
      }
    end
    
    def destroy_others_position
      @others_position.destroy
      $pms_logger.info("UpdatePortfolio: 删除为0之others,account_id = #{@account.id},symbol = #{symbol}") if Setting.pms_logger
    end
    
    def others_shares
      @others_position.shares.to_i
    end
    
    def after_shares
      position.to_i - Position.account_with(@account.id).stock_with(@stock.id).basket_invest.sum(:shares)
    end
    
    def update_others_position
      @others_position.update_others_position(after_shares, average_cost)
      $pms_logger.info("UpdatePortfolio: 直接更新others,#{after_shares},account_id=#{@account.id},symbol=#{symbol}") if Setting.pms_logger
    end
    
    def adjust_reconcile_request
      $pms_logger.info("UpdatePortfolio: 未能调平,account_id=#{@account.id},symbol=#{symbol}") if Setting.pms_logger
      create_reconcile_request!
      premote_reconcile_level
      move_shares_to_unallocate
    end

    def move_shares_to_unallocate
      ::Position.find_or_initialize_by(instance_id: "unallocate", base_stock_id: @stock.id, trading_account_id: @account.id).update(shares: position.to_i - Position.account_with(@account.id).stock_with(@stock.id).allocated.sum(:shares))
    end
    
    def create_reconcile_request!
      ::ReconcileRequestCts.find_or_initialize_by(trading_account_id: @account.id).update_broker_user_id_and_symbol(account_name, @stock.ib_symbol, "updatePortfolio")
    end
    
    def portfolio_changed?
      @before_portfolio != position.to_i
    end
    
  end #UpdatePortfolioHandler
  
end #Trading
