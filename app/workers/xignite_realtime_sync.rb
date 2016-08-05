class XigniteRealtimeSync
  @queue = :xignite_rt

  def self.perform(symbols = '')
    if symbols.blank?
      
      # 如果是美股交易时间,抓取美股实时数据
      if now_us_trading?
        BaseStock.except_sehk.trading_normal.select(:xignite_symbol).pluck(:xignite_symbol).in_groups_of(300).each do |symbols|
          Resque.enqueue(XigniteRealtimeSync, symbols.compact.join(','))
        end
      end
      
      # 港股交易时间抓取港股实时数据
      if now_hk_trading?
        BaseStock.sehk.trading_normal.select(:xignite_symbol).pluck(:xignite_symbol).in_groups_of(300).each do |symbols|
          Resque.enqueue(XigniteRealtimeSync, symbols.compact.join(','))
        end
      end

    else
      Xignite::RealTime::Base.new(symbols.to_s.split(',').compact).sync
    end
  end

  def self.now_us_trading?
    Time.now.strftime('%H%M').to_i.between?(2130, 2359) || Time.now.strftime('%H%M').to_i.between?(0, 530)
  end

  def self.now_hk_trading?
    Time.now.strftime('%H%M').to_i.between?(930, 1630)
  end

end
