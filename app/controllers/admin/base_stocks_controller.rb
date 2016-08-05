class Admin::BaseStocksController < Admin::ApplicationController
  def index
    @page_title = "个股主数据"
    @q = BaseStock.order_by_id.search(params[:q])
    if created_at_day_exists?
      @created_at_day = params[:q][:created_at_day]
      @base_stocks = @q.result.created_at_day(@created_at_day).paginate(page: params[:page] || 1, per_page: params[:per_page] || 20).to_a
    else
      @base_stocks = @q.result.paginate(page: params[:page] || 1, per_page: params[:per_page] || 20).to_a
    end

    @exchange_eq =  params[:q][:exchange_eq] rescue nil
    
    respond_to do |format|
      format.html 
      format.csv { send_data @base_stocks.to_csv }
      format.xls { send_data @base_stocks.to_csv(col_sep: "\t") }
    end
  end

  def edit
    @base_stock = BaseStock.find(params[:id])
  end

  def list
    @page_title = "个股主数据"
    @q = BaseStock.order_by_id.search(params[:q])
    
    @base_stocks = @q.result.paginate(page: params[:page] || 1, per_page: params[:per_page] || 20).to_a
  end

  def unqualified_list
    @page_title = "不可加入组合的股票列表"
    @q = BaseStock.where(qualified: false).order_by_id.search(params[:q])

    @base_stocks = @q.result.paginate(page: params[:page] || 1, per_page: params[:per_page] || 20).to_a
  end

  def reset_cn_qualified
    BaseStock.cn.where(listed_state: BaseStock::LISTED_STATE[:normal],stock_type: nil, qualified: false).update_all(qualified: true)

    
    render js: "alert('success');window.location.reload();"
  end

  def reset_neeq_qualified
    BaseStock.where(exchange: 'NEEQ').update_all(qualified: false)

    render js: "alert('success');window.location.reload();"
  end

  def reset_tf_cache
    RestClient.api.stock.trading_flow.reset_cache(params[:stock_id])
     
    render js: "alert('success');window.location.reload();"
  end

  def import_c_name
    if !params[:file].nil?
      begin
        BaseStock.import_c_name(params[:file])
        message = "导入成功"
      rescue Exception => e
        message = "导入失败，请确认文件类型为csv、xls或xlsx"
      end
    else
      message = "请选择文件"
    end
    redirect_to admin_base_stocks_path, notice: message
  end
  
  def get_qualified_info
    base_stock_id = params[:base_stock_id]
    if @base_stock = BaseStock.find(base_stock_id)
      @qualified_info = @base_stock.get_qualified_info
    end
  end
  
  def get_snapshot_info
    base_stock_id = params[:base_stock_id]
    if @base_stock = BaseStock.find(base_stock_id)
      @snapshot = @base_stock.get_snapshot
    end
  end
  
  def setting
    @page_title = "个股图片"
    @stock = BaseStock.find(params[:id])
  end
  
  def update
    @page_title = "个股图片"
    @stock = BaseStock.find(params[:id])
    @stock.update(base_stock_params)
    #@stock.update(img: params[:base_stock][:img])
    redirect_to params[:referer_url] || admin_base_stocks_path 
  end
  
  def reset_bar
    RestClient.api.stock.cn_bar.reset(params[:id])

    render js: "alert('success');window.location.reload();"
  end

  def fill_bar
    RestClient.api.stock.cn_bar.fill(params[:id])

    render js: "alert('success');window.location.reload();"
  end

  def reset_bar_by_exchange
    RestClient.api.stock.cn_bar.reset_by_exchange(params[:exchange])

    render js: "alert('success');window.location.reload();"
  end

  def fill_bar_by_exchange
    RestClient.api.stock.cn_bar.fill_by_exchange(params[:exchange])
    
    render js: "alert('success');window.location.reload();"
  end

  def reset_quote
    RestClient.api.stock.cn_bar.reset_historical_quote(params[:id])

    render js: "alert('success');window.location.reload();"
  end
  
  def reset_4days_bar
    RestClient.api.stock.cn_bar.reset_4days_bars(params[:id])

    render js: "alert('success');window.location.reload();"
  end

  def reset_4days_bar_by_exchange
    RestClient.api.stock.cn_bar.reset_cn_4days_bars_by_area(params[:exchange])

    render js: "alert('success');window.location.reload();"
  end

  def split_and_dividend_list
    @page_title = "分红分股列表页面"
    
    @splits = RestClient.api.stock.split_and_dividend_list(params[:id])
    @splits = [] unless @splits.is_a?(Array)
  end

  def reset_cn_rt
    RestClient.api.stock.cn_bar.reset_cn_rt(params[:base_stock_id])

    render js: "alert('success');window.location.reload();"
  end
  
  # 重置停牌股票交易时间
  def reset_halted_trade_time
    Resque.enqueue(ResetHaltedTradeTime) 
    render js: "alert('success');window.location.reload();"
  end
  
  # 抓取停牌股票
  def halted_fetch
    EventQueue::DataProcess.publish({type: "halted_stock_fetch", cn: true})
    render js: "alert('success');window.location.reload();"
  end

  # 重置分时图数据
  def reset_minute_charts
    EventQueue::DataProcess.publish({type: 'reset_minute_charts', day: params[:day], market: params[:market], stock_id: params[:stock_id]})

    render js: "alert('success');window.location.reload();"
  end
  
  # 重置实时数据
  def reset_rt
    EventQueue::DataProcess.publish({type: 'reset_rt', market: params[:market], stock_id: params[:stock_id]})
  
    render js: "alert('success');window.location.reload();"
  end

  private
  def created_at_day_exists?
    !params[:q].blank? && !params[:q][:created_at_day].blank?
  end

  def base_stock_params
    params.require(:base_stock).permit([:listed_state, :exchange, :normal, :qualified])
  end
end
