namespace :account_property do
  desc "重跑6/17账户净值"
  task :fix => :environment do
    TradingAccountPT.find_each do |account|
      last_total_cash = AccountValueArchive.find_by(trading_account_id: account, archive_date: '2015-06-17', key: 'LastTotalCash')
      total_cash_balance = AccountValueArchive.find_by(trading_account_id: account, archive_date: '2015-06-17', key: 'TotalCashBalance')
      if last_total_cash && total_cash_balance
        puts "#{account.id} #{last_total_cash.value} #{total_cash_balance.value}"
        total_cash_balance.update(value: last_total_cash.value)
        
        UserDayProperty.sync(account, Date.parse('2015-06-17'))
      else
        puts "#{account.id} 不存在!!!!!!"
      end
    end
    

  end
end
