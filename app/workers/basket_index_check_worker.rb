class BasketIndexCheckWorker
  @queue = :basket_index_check_worker

  # 每天早上2点执行全部组合，A股港股执行最近一交易日，美股执行上一交易日的
  def self.perform
    areas = %w(us hk cn)
    areas.each do |area|
      compare_date = area == "us" ? Date.today-2 : Date.yesterday
      date = ClosedDay.get_work_day(compare_date, area)
      bids = Basket.where(market: area).normal.public_finished.select(:id).map(&:id)
      bi_count = BasketIndex.where(date: date, basket_id: bids).count

      send_mail("#{date} #{area} 没有basket index 数据") if bi_count.zero?

      prev_workday = ClosedDay.get_work_day(date-1, area)
      waning_ids = []
      BasketIndex.where(date: date, basket_id: bids).select(:id, :index, :basket_id).find_each do |bi|
        prev_bi = BasketIndex.where(date: prev_workday, basket_id: bi.basket_id).select(:index).last
        next if prev_bi.blank?
        waning_ids.push(bi.basket_id) if (bi.index - prev_bi.index).abs*100/bi.index >= 10
      end
      send_mail("#{date} #{waning_ids.join(",")} 指数涨跌异常") if waning_ids.present?
    end
  end

  def self.send_mail(text)
    Caishuo::Utils::Email.deliver("wangzhichao@caishuo.com", text, "#{Rails.env}组合指数报警")
  end
end