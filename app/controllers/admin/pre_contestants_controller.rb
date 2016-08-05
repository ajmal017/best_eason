class Admin::PreContestantsController < Admin::ApplicationController

  def index
    @contestants = PreContestant.order(id: :desc).paginate(page: params[:page]||1, per_page: 20)
  end
end