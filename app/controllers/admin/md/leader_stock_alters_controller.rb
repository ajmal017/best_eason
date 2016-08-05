class Admin::Md::LeaderStockAltersController < Admin::ApplicationController

  def index
    @page_title = "高管最近一个月持仓变化列表"
    
    criteries = ::MD::Data::LeaderStockAlter
    %W{base_stock_id}.each do |field|
      criteries = criteries.where(field => params[field]) if params[field].present?
    end

    if params[:sort_value]
      criteries = criteries.order(:value => params[:sort_value])
    end

    @alters = criteries.paginate(page: params[:page] || 1, per_page: params[:per_page] || 20)
  end

end
