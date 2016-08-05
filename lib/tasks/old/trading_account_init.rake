namespace :caishuo do
  desc 'trading account init'
  task :trading_account_init => :environment do
    
    UserBinding.find_each do |user_binding|
      trading_account = TradingAccountEmail.find_or_create_by(broker_no: user_binding.broker_user_id, user_id: user_binding.user_id, broker_id: user_binding.broker_id) 
      trading_account.update(user_binding.attributes.symbolize_keys.slice(:base_currency, :count, :portfolioable, :updated_by, :trading_since))
      trading_account.update(status: 1)

      puts trading_account.id

      Position.where(user_id: trading_account.user_id).update_all(trading_account_id: trading_account.id)
      PositionArchive.where(user_id: trading_account.user_id).update_all(trading_account_id: trading_account.id)
      AccountValue.where(user_id: trading_account.user_id).update_all(trading_account_id: trading_account.id)
      AccountValueArchive.where(user_id: trading_account.user_id).update_all(trading_account_id: trading_account.id)
      UserDayProperty.where(user_id: trading_account.user_id).update_all(trading_account_id: trading_account.id)
      UserProfit.where(user_id: trading_account.user_id).update_all(trading_account_id: trading_account.id)
      Portfolio.where(user_id: trading_account.user_id).update_all(trading_account_id: trading_account.id)
      PortfolioArchive.where(user_id: trading_account.user_id).update_all(trading_account_id: trading_account.id)
      Order.where(user_id: trading_account.user_id).update_all(trading_account_id: trading_account.id)
      OrderDetail.where(user_id: trading_account.user_id).update_all(trading_account_id: trading_account.id)
      ExecDetail.where(user_id: trading_account.user_id).update_all(trading_account_id: trading_account.id)
      IbPosition.where(user_id: trading_account.user_id).update_all(trading_account_id: trading_account.id)
      OrderLog.where(user_id: trading_account.user_id).update_all(trading_account_id: trading_account.id)
      ReconcileRequestList.where(user_id: trading_account.user_id).update_all(trading_account_id: trading_account.id)
      ExchangeRate.where(user_id: trading_account.user_id).update_all(trading_account_id: trading_account.id)
    end

    InvestmentCache.perform
    
    puts "====END==="
  end
end
