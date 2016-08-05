class Admin::Md::LonghusController < Admin::ApplicationController

  def index
    @page_title = "龙虎榜列表"
    
    criteries = ::MD::Data::Longhu.order(id: :desc)
    %W{base_stock_id date}.each do |field|
      criteries = criteries.where(field => params[field]) if params[field].present?
    end

    if params[:reason_type]
      criteries = criteries.where(reason: MD::Data::Longhu::REASON_TYPES[params[:reason_type].to_i])
    elsif params[:reason].present?
      criteries = criteries.where(reason: Regexp.new(params[:reason]))  
    end

    @longhus = criteries.paginate(page: params[:page] || 1, per_page: params[:per_page] || 20)
  end

end
