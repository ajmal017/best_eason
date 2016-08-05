class StockScreener < ActiveRecord::Base
  belongs_to :base_stock
  
  # 高质量的股票列表
  scope :qualified, -> { joins(:base_stock).where("base_stocks.exchange in ('SSE', 'SZSE') and base_stocks.normal = true and base_stocks.listed_state = 1 and base_stocks.stock_type is null")}

  def competitors
    stock_ids = [self.base_stock_id] + self.competitor_ids
    BaseStock.where(id: stock_ids).includes(:stock_screener)
  end

  %w[pe lpg cf gm wst div].each do |type|
    define_method "score_#{type}_comparison" do
      self_index, avg_index = self.try("#{type}"), self.try("#{type}_c")
      return nil unless self_index && avg_index

      high_label = type == "cf" ? "强" : "高"
      low_label  = type == "cf" ? "弱" : "低"

      self_index.to_f >= avg_index.to_f ? high_label : low_label
    end
  end

  def score_type_name(type)
    case type.to_s
    when "pe"
      "市盈率"
    when "lpg"
      base_stock.is_a?(Stock::Cn) ? "主业务" : "长期盈利"
    when "cf"
      "现金流"
    when "gm"
      "毛利润"
    when "wst"
      "资产回报"
    when "div"
      "市净值"
    end
  end

  # title: 标题 index: 指数 label: 高低
  def score_values
    %w[pe lpg cf gm wst div].map do |type|
      {title: score_type_name(type), index: self.try("#{type}_r").try(:to_f), label: self.send("score_#{type}_comparison")}
    end
  end

  def competitor_ids
    (1..20).map{|num| self.send("c#{num}".to_sym)}.compact
  end

  # for feeds
  def pretty_json
    {
      id: base_stock_id,
      name: base_stock.com_name,
      type: 'stock',
      symbol: base_stock.symbol
    }
  end

  private
  def stock_screener_comparison(self_index, avg_index, high_label, low_label, reverse = false)
    return nil unless self_index && avg_index
    em_label = self_index.to_f >= avg_index.to_f ? high_label : low_label
  end
  
  def self.import_sector(screeners)
    ImportProxy.import(
      StockScreener, 
      [:sector_bm, :sector_c, :sector_cg, :sector_f, :sector_h, :sector_ig, :sector_s, :sector_t, :sector_u, :sector_o, :base_stock_id], 
      screeners, 
      validate: false, 
      on_duplicate_key_update: [:sector_bm, :sector_c, :sector_cg, :sector_f, :sector_h, :sector_ig, :sector_s, :sector_t, :sector_u, :sector_o]
    )
  end
  
  def self.import_trend(screeners)
    ImportProxy.import(
      StockScreener, 
      [:trend_g10, :trend_l10, :trend_h52, :trend_l52, :change_rate, :symbol, :base_stock_id], 
      screeners, 
      validate: false, on_duplicate_key_update: [:trend_g10, :trend_l10, :trend_h52, :trend_l52, :change_rate, :symbol]
    )
  end
end
