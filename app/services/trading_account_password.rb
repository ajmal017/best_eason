class TradingAccountPassword < TradingAccount
  before_create :set_feed_type
  
  # A股现金余额
  def total_cash
    usable_cash + frozen_cash
  end
  
  CSV_NAMES = ["broker_no", "password"]

  # TODO 状态新建
  def self.daily_citics_to_csv(options = {})
    CSV.generate(options) do |csv|
      csv << CSV_NAMES
      where(created_at: Date.today.at_beginning_of_day..Date.today.at_end_of_day, status: STATUS[:new]).each do |account|
        csv << account.attributes.values_at(*CSV_NAMES)
      end
    end
  end

  def self.deliver_to_citics
    file_content = self.daily_citics_to_csv
    return if file_content.size <= CSV_NAMES.join(",").size.next

    Mail.new do
      from     '财说-系统01 <system01@caishuo.com>'
      to       Setting.citics.emails
      subject  "#{Date.today}申请中信账号绑定审核列表"
      add_file :filename => "citics_#{Date.today.to_s(:db)}.csv", :content => file_content
    end.deliver
  end

  def category_name
    "A股账号"
  end
  
  private
  
  def set_feed_type
    self.feed_type = :trading_account
  end

end
