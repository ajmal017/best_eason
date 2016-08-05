class Mobile::BasketsController < Mobile::ApplicationController
  before_action :adjust_search_params
  
  layout 'mobile'
  def index
    set_pc_link("/baskets")
    @body_class = "themeListMobile"
    @page_title = "组合投资"
    @search = params.fetch(:search, {}).select{|k,v| v.present? }
    @order_param = (@search[:order] ||= '1m_return')
    @baskets = Basket.includes(:tags).search_list(@search.dup).paginate(page: params[:page] || 1,  per_page: params[:per_page] || 15)
    
    data = ->{
      return_field = Basket::SEARCH_ORDER_MOBILE_RETURN_NAME_MAP.keys.include?(@order_param) ? Basket::SEARCH_ORDER_FIELD_MAP[@order_param] : "one_month_return"
      lists = []
      @baskets.each do |basket|
        return_value = basket.public_send(return_field)
        lists << {
                   gain: (return_value.round(2) rescue '0.00'), 
                   market: "#{basket.market}", 
                   tags: basket.tags[0..2].map(&:name), 
                   title: basket.title, 
                   username: basket.author.username, 
                   modified_at: basket.modified_at, 
                   link: mobile_link("/mobile/baskets/#{basket.id}")
                 } 
      end
      lists
    }
    
    
    respond_to do |format|
      format.html
      format.json {render :json => {lists: data.call, nextPage: @baskets.next_page.blank? ? 0 : 1}.to_json}
    end
  end

  def show
    show_data
  end
  
  def content
    show_data
    render "show"
  end

  def info
    @basket = Basket.find(params[:id])
    @page_title = '投资理念'
    render layout: "mobile/common"
  end

  private

  def adjust_search_params
    unless request.xhr?
      @keyword = params[:q]
      redirect_to mobile_link "#{"/mobile" if Rails.env.development?}/baskets?search[search_word]=#{URI.encode(@keyword)}" and return if @keyword.present?
    end
  end
  
  def show_data
    @basket = Basket.find(params[:id])
    @tags = @basket.tags.map(&:name).unshift(@basket.market_name)
    @page_title = @basket.mobile_page_title
    logs = @basket.adjust_logs.first.try(:basket_adjust_logs)||[]
    @logs_hash = Hash[logs.map{|log| [log.stock_id, log.action] }]
    @weights_hash = Hash[@basket.basket_stocks.map{|bs| [bs.stock_id, bs.weight_percent] }]
    @stocks = BaseStock.where(id: @basket.basket_stocks.map(&:stock_id)+@logs_hash.keys)
    @groups = @stocks.inject(Hash.new { |hash, key| hash[key] = { num: 0, color: nil, stocks:[] } }) do |hash, stock|
      hash[stock.try(:sector_name)][:num] += (@weights_hash[stock.id] || 0)
      hash[stock.try(:sector_name)][:color]||= stock.try(:sector_color)
      hash[stock.try(:sector_name)][:stocks]<<stock
      hash
    end
    if @basket.cash_weight > 0
      @groups[Sector::C_MAPPING["0"]][:num] = @basket.cash_weight_percent
      @groups[Sector::C_MAPPING["0"]][:color] = Sector::COLORS["0"]
    end

    set_pc_link("/baskets/#{@basket.id}")
  end

end