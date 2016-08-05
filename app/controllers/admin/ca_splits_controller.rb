class Admin::CaSplitsController < Admin::ApplicationController
  def index
    @page_title = "拆股股票列表"
    @q = CaSplit.search(params[:q])
    @ca_splits = @q.result.order(id: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page] || 20).to_a
  end
end
