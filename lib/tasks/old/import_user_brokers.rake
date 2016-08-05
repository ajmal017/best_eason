namespace :caishuo do
  desc 'import user brokers'
  task :import_user_brokers => :environment do
    
    UserBroker.where(status: [0, 2]).order(id: :asc).each do |user_broker|
      puts "user_brokers #{user_broker.id}"
      accounts = TradingAccountEmail.where(user_id: user_broker.user_id, broker_no: user_broker.broker_no, broker_id: user_broker.broker_id)
      unless accounts.any?{|x| x.status == 1}
        attrs = user_broker.attributes.symbolize_keys.slice(:user_id, :broker_no, :broker_id, :email, :confirmation_token, :confirmation_sent_at, :status)
        trading_account = TradingAccountEmail.create(attrs)
        puts trading_account.id
      end
    end

    puts "====END==="
  end
end
