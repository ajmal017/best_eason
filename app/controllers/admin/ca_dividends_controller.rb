class Admin::CaDividendsController < Admin::ApplicationController
  def index
    @page_title = "股票分红抓取列表"
    @q = CaDividend.search(params[:q])
    @ca_dividends = @q.result.order(id: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page] || 20)
  end
end
