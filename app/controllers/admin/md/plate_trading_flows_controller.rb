class Admin::Md::PlateTradingFlowsController < Admin::ApplicationController

  def index
    @page_title = "板块资金流向列表"
    
    criteries = ::MD::Data::PlateTradingFlow.order(main_value: :desc)
    %W{name _type}.each do |field|
      criteries = criteries.where(field => Regexp.new(params[field])) if params[field].present?
    end
    @flows = criteries.paginate(page: params[:page] || 1, per_page: params[:per_page] || 20)
  end

end
