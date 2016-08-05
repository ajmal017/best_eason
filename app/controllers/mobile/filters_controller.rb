class Mobile::FiltersController < Mobile::ApplicationController

  before_action :hide_iclick, :hide_page_title_postfix

  layout 'mobile'

  after_action :click_feed_hub

  # 行业板块资金流向
  def zjbklx_1
    @page_title = "今日行业板块主力资金流入"
    @filters = MD::FeedRecommendFilter.find(:filter_zjbklx_1, 100)
    @update_date = @filters.first.try(:updated_at).try(:to_date).try(:to_s, :db)
    render :plates_flow
  end

  # 概念板块资金流向
  def zjbklx_2
    @page_title = "今日概念板块主力资金流入"
    @filters = MD::FeedRecommendFilter.find(:filter_zjbklx_2, 100)
    @update_date = @filters.first.try(:updated_at).try(:to_date).try(:to_s, :db)
    render :plates_flow
  end

  # 热门行业
  def industry_1
    @page_title = "热门行业"
    @filters = MD::FeedRecommendFilter.find(:filter_industry_1, 100)
    render :plates
  end

  # 热门概念
  def concept_1
    @page_title = "热门概念"
    @filters = MD::FeedRecommendFilter.find(:filter_concept_1, 100)
    render :plates
  end

  # 个股主力净流入
  def ggzjlx_1
    @page_title = "个股主力净流入列表"
    @filters = MD::FeedRecommendFilter.find(:filter_ggzjlx_1, 50)
    @rs_stocks = ::MD::RS::Stock.where(:base_stock_id.in => @filters.map(&:base_stock_id))
                   .map{|s| [s.base_stock_id, s]}.to_h
    set_update_date
  end

  # 个股主力净流出
  def ggzjlx_2
    @page_title = "个股主力净流出列表"
    @filters = MD::FeedRecommendFilter.find(:filter_ggzjlx_2, 50)
    @rs_stocks = ::MD::RS::Stock.where(:base_stock_id.in => @filters.map(&:base_stock_id))
                   .map{|s| [s.base_stock_id, s]}.to_h
    set_update_date
  end

  # 高管增持
  def ggcg_1
    @page_title = "高管最近一个月增持列表"
    @filters = MD::FeedRecommendFilter.find(:filter_ggcg_1, 500)
    @update_date = @filters.first.try(:updated_at).try(:to_date).try(:to_s, :db)
    render 'ggcg'
  end

  # 高管减持
  def ggcg_2
    @page_title = "高管最近一个月减持列表"
    @filters = MD::FeedRecommendFilter.find(:filter_ggcg_2, 500)
    @update_date = @filters.first.try(:updated_at).try(:to_date).try(:to_s, :db)
    render 'ggcg'
  end

  # 当日涨幅偏离值达7%的证券
  def lhb_1
    @page_title = "当日涨幅偏离值达7%的证券"
    @filters = MD::FeedRecommendFilter.find(:filter_lhb_1, 100)
    set_update_date
    get_stocks
    render "lhb"
  end

  # 当日跌幅偏离值达7%的证券
  def lhb_2
    @page_title = "当日跌幅偏离值达7%的证券"
    @filters = MD::FeedRecommendFilter.find(:filter_lhb_2, 100)
    set_update_date
    get_stocks
    render "lhb"
  end

  # 当日换手率达到20%的证券
  def lhb_3
    @page_title = "当日换手率达到20%的证券"
    @filters = MD::FeedRecommendFilter.find(:filter_lhb_3, 100)
    set_update_date
    get_stocks
    render "lhb"
  end

  # 当日价格振幅达到15%的证券
  def lhb_4
    @page_title = "当日价格振幅达到15%的证券"
    @filters = MD::FeedRecommendFilter.find(:filter_lhb_4, 100)
    set_update_date
    get_stocks
    render "lhb"
  end

  # 连续三个交易日收盘价涨幅偏离值累计20%
  def lhb_5
    @page_title = "连续三日涨幅累计超20%"
    @filters = MD::FeedRecommendFilter.find(:filter_lhb_5, 100)
    set_update_date
    get_stocks
    render "lhb"
  end

  # 连续三个交易日收盘价跌幅偏离值累计20%
  def lhb_6
    @page_title = "连续三日跌幅累计超20%"
    @filters = MD::FeedRecommendFilter.find(:filter_lhb_6, 100)
    set_update_date
    get_stocks
    render "lhb"
  end

  # 财说Score高评分
  def score_1
    @page_title = "财说SCORE高评分 买入策略"
    @header_class = "buy"
    @filters = MD::FeedRecommendFilter.find(:filter_score_1, 20)
    process_stock_screener_filters
    get_stocks
    render "tech_indices"
  end

  # 财说Score低评分
  def score_2
    @page_title = "财说SCORE低评分 卖出策略"
    @header_class = "sell"
    @filters = MD::FeedRecommendFilter.find(:filter_score_2, 20)
    process_stock_screener_filters
    get_stocks
    render "tech_indices"
  end

  def wr_1
    @page_title = "WR超卖 买入策略"
    @header_class = "buy"
    @filters = MD::FeedRecommendFilter.find(:filter_wr_1, 50)
    set_update_date
    get_stocks
    render "tech_indices"
  end

  def wr_2
    @page_title = "WR超买 卖出策略"
    @header_class = "sell"
    @filters = MD::FeedRecommendFilter.find(:filter_wr_2, 50)
    set_update_date
    get_stocks
    render "tech_indices"
  end

  def macd_1
    @page_title = "MACD金叉 买入策略"
    @header_class = "buy"
    @filters = MD::FeedRecommendFilter.find(:filter_macd_1, 50)
    set_update_date
    get_stocks
    render "tech_indices"
  end

  def macd_2
    @page_title = "MACD死叉 卖出策略"
    @header_class = "sell"
    @filters = MD::FeedRecommendFilter.find(:filter_macd_2, 50)
    set_update_date
    get_stocks
    render "tech_indices"
  end

  private
  def set_update_date
    @update_date = @filters.first.try(:date).try(:to_date).try(:to_s, :db)
  end

  def get_stocks
    @stocks = BaseStock.where(id: @filters.map(&:base_stock_id)).select(:id, :symbol, :c_name, :name, :listed_state).sort_by do |stock|
      stock.trading_halt? ? -100 : stock.change_percent
    end.reverse
  end

  # 财说score取的stock_screener与其它指标属性不一致，此处做转换，公用一个render页面
  def process_stock_screener_filters
    @filters = @filters.map do |s|
      OpenStruct.new({base_stock_id: s.base_stock_id})
    end
    @update_date = Exchange::Base.by_area(:cn).prev_latest_market_date
  end



  def click_feed_hub
    source_id = "filter_#{params[:action]}"
    return unless MD::FeedRecommendFilter::FILTER_TYPES.include?(source_id.to_sym)
    MD::FeedHub.click('Filter', source_id.to_sym, app_uuid) if mobile_request?
  end

end
