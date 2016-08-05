require "typhoeus"
class P2pStrategy < ActiveRecord::Base
  include Screenshot

  BASE_TYPE = [["股票", "stock"],["指数", "index"]]
  CHANGE_TYPE = [["上涨", "up"], ["下跌", "down"]]

  belongs_to :staffer, class_name: 'Admin::Staffer', foreign_key: :staffer_id
  belongs_to :mentionable, polymorphic: true

  validates_numericality_of :weight, greater_than: 0, less_than_or_equal_to: 1

  default_scope -> { includes(:staffer, :mentionable)  }
  scope :desc, -> { order id: :desc  }

  def base_type_zh
    BASE_TYPE.find{|n| self.base_type == n.last }.try(:first)
  end

  def change_type_zh
    CHANGE_TYPE.find{|n| n.last == change_type}.try(:first)
  end

  def to_s
    "策略类型：#{base_type_zh}, 关联对象：#{mentionable.try(:c_name)}, 涨跌类型：#{change_type_zh}, 权重：#{weight}"
  end

  def profit(start_date, end_date = Date.today)

    start_date = adjust_date(start_date)
    end_date = adjust_date(end_date)

    raise "结束日期不能小于开始日期" unless end_date >= start_date
    raise "结束日期不能大于今天" unless end_date <= Date.today

    start_price = date_price(start_date)
    end_price = date_price(end_date)

    pm = change_type == "up" ? 1 : -1

    {
      interest_rate: (((end_price - start_price) / start_price) * pm * weight).to_f.round(4),
      start_date_index: start_price,
      end_date_index: end_price
    }
  end

  def current_market
    mentionable.market_area
  end

  def index_image
    $cache.fetch("p2p:strategy:#{id}:index_image:#{Date.today.strftime('%Y%m%d')}", expires_in: 1.day){ catch_scrrenshot(mirror_img_url) }
  end

  def adjust_date(date)
    # 如果未开市,则把日期调整到前一天
    date = date.yesterday if date == Date.today && Exchange::Base.by_area(current_market).market_unopen?
    # 调整时间到上一个交易日当天
    ClosedDay.get_work_day(date, current_market)
  end

  def base_historical_quote_class
    (mentionable.is_cn? ? HistoricalQuoteCn : HistoricalQuote).where(base_stock_id: mentionable.id)
  end

  def date_price(date)
    if date == Date.today
      mentionable.realtime_price
    else
      record = base_historical_quote_class.where(date: date)
      raise "没有找到#{date.to_s}的数据" unless record.present?
      record.first.last_close rescue nil
    end.to_f.round(2)
  end

  def mirror_img_url(stock_id=self.mentionable_id, change_type=self.change_type)
    "#{Setting.host}/image_mirrors/p2p_product_img?stock_id=#{stock_id}&change_type=#{change_type}&date=#{Date.today.strftime('%Y%m%d')}"
  end

  def format_data
    {
      id: id,
      title: to_s,
      mentionable_id: mentionable_id,
      mentionable_type: mentionable_type,
      type: change_type,
      weight: weight
    }
  end

end
