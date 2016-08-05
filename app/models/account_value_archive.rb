class AccountValueArchive < ActiveRecord::Base

  ARCHIVED_FIELDS = %W{ user_id broker_user_id key currency value trading_account_id}

  # 如果currency为BASE的话则取base_currency
  def currency
    current_currency = read_attribute(:currency)
    current_currency == "BASE" ? base_currency : current_currency
  end

  # 可用现金
  def total_cash(account_currency = nil)
    account_currency ? value * Currency.transform(currency, account_currency) : value
  end

  def value
    read_attribute(:value).to_f
  end
  
  # 每天美股闭市之后同步现金余额
  def self.sync(date)
    $investment_logger.info("正在归档account_value...#{date.to_s(:db)}")
    
    AccountValue.find_in_batches(batch_size: 2000) do |account_values|  
      currencies = TradingAccount.where(id: account_values.map(&:trading_account_id).uniq).map{|account|[account.id, account.base_currency]}.to_h

      imports = account_values.map do |av|
        attrs = av.attributes.slice(*ARCHIVED_FIELDS).merge(archive_date: date, base_currency: currencies[av.trading_account_id])
        self.new(attrs)
      end

      self.import(imports)
    end
  rescue Exception => e
    Caishuo::Utils::Email.deliver(Setting.investment_notifiers.email, Rails.env, "现金余额归档出错:#{date.to_s(:db)} #{e.message}")
  end

end
