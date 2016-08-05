class InvestmentCache
  @queue = :investment

  def self.perform
    # 同步持仓最多的个股
    Investment.sync_popular_stocks 
    # 同步投资胜率
    Investment.sync_winning_ratio
    # 同步投资行业分布比例
    Investment.sync_sector_ratio
    # 清除失效的行业投资比例
    Investment.clear_expired_sector_ratio
    # 同步收益变动
    Investment.sync_profit_fluctuation
    # 同步用户每月平均收益
    Investment.sync_one_month_return
    # 同步30天内用户平均收益
    Investment.sync_30days_average_position
    # 比一比
    Investment.sync_friends_property_rank
    Investment.sync_total_property_rank
  end
end
