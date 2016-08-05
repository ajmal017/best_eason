class Admin::SurveysController < Admin::ApplicationController
  def index
    @page_title = "调查内容"
    @surveys = Survey.order("id desc")
    @paginated_surveys = @surveys.paginate(page: params[:page] || 1, per_page: params[:per_page] || 30)
  end
end
