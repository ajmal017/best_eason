# 组合搜索
#   search_params keys：
#   keyword(or search_word), market, tag, order, page, per_page
class BasketSearch
  attr_accessor :params

  ORDER_FIELDS_MAP = {
    "contest_return" => "contest_return",
    "1m_return" => "one_month_return",
    "1y_return" => "one_year_return",
    "1d_return" => "one_day_return",
    "start_date" => "start_on",
    "bullish" => "bullish_percent",
    "hot" => "hot_score",
    "modified_at" => "modified_at",
    "total_return" => "total_return",
    "adjustment_at" => "adjustment_at"
  }.with_indifferent_access

  ORDER_RETURN_NAME_MAP = {
    "contest_return" => "大赛成绩",
    "1m_return" => "1月回报",
    "1y_return" => "1年回报",
    "1d_return" => "1日回报",
    "total_return" => "至今回报"
  }.with_indifferent_access

  ORDER_MOBILE_RETURN_NAME_MAP = {
    "1m_return" => "月收益",
    "1y_return" => "年收益",
    "1d_return" => "日收益",
    "total_return" => "总收益"
  }.with_indifferent_access

  def initialize(search_params)
    @params = search_params.with_indifferent_access
  end

  def self.exec(params)
    new(params).exec
  end

  def exec
    Basket.__elasticsearch__.search(es_params).paginate(page: page, per_page: per_page)
  end

  private

  def es_params
    conditions = {}
    conditions.merge!(query: query_params) if query_params.present?
    conditions.merge!(filter: filter_params)
    conditions.merge!(sort: sort_params)
    conditions.merge!(highlight: { fields: { title: {} } })
    conditions
  end

  def query_params
    query = {}
    query.merge!(multi_match: multi_match_params) if keyword.present?
    query
  end

  def multi_match_params
    {
      query: keyword,
      fields: [{ title: { boost: 4 } }, { abbrev: { boost: 2 } }, :cleaned_description],
      type: "best_fields", minimum_should_match: "100%",
      tie_breaker: 0.5
    }
  end

  def filter_params
    filters = [{ class_type: "Basket::Normal" }, { state: Basket::STATE[:normal] }, { visible: true }]
    filters << { market: market } if market.present?
    filters << { tag_ids:  tag_id } if tag_id.present? && tag_id != "all"
    { bool: { must: filters.map { |filter| { term: filter } } } }
  end

  def sort_params
    order_field = ORDER_FIELDS_MAP[params[:order]]
    return { order_field => { order: "desc" } } if order_field.present?
    { id: { order: "desc" } }
  end

  def keyword
    params[:search_word] || params[:keyword]
  end

  def market
    Basket::MARKETS[params[:market]]
  end

  def tag_id
    params[:tag]
  end

  def page
    params[:page] || 1
  end

  def per_page
    params[:per_page] || 9
  end
end
