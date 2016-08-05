class Admin::Md::StockTradingFlowsController < Admin::ApplicationController

  def index
    @page_title = "个股资金流向"
    
    criteries = ::MD::Data::StockTradingFlow
    %W{base_stock_id}.each do |field|
      criteries = criteries.where(field => params[field]) if params[field].present?
    end
    
    if params[:sort_main_value]
      criteries = criteries.order(:main_value => params[:sort_main_value])
    end
    
    @flows = criteries.paginate(page: params[:page] || 1, per_page: params[:per_page] || 20)
  end

end
