namespace :caishuo do
  desc 'PT trading account import'
  task :pt_trading_account_import => :environment do
    broker_id = Broker.find_by!(name: 'PT')
    master_account = TradingAccount.find_by!(broker_no: Setting.pt_master_account)
    xlsx = Roo::Spreadsheet.open(File.join(Rails.root, 'public', 'pt_trading_account.xlsx'))
    xlsx.each_with_pagename do |name, sheet|
      1.upto(sheet.last_row) do |row_no|
        cs_id, broker_no = sheet.row(row_no)
        cs_id = cs_id.to_i
        p "cs_id = #{cs_id}; broker_no = '#{broker_no}'"
        TradingAccountPT.create(user_id: cs_id, broker_no: broker_no, broker_id: broker_id, status: 1, cash_id: broker.master_account+'_'+broker_no)
      end
    end
  end
end
