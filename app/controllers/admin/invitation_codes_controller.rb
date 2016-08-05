class Admin::InvitationCodesController < Admin::ApplicationController
  def index
    @page_title = "邀请码列表页面"
    @q = InvitationCode.includes(:lead).order(id: :desc).search(params[:q])
    @invitation_codes = @q.result.paginate(page: params[:page] || 1, per_page: params[:per_page] || 10).to_a
  end

  def new
    @invitation_code = InvitationCode.new
  end

  def create
    if request.xhr?
      @invitation_code = InvitationCode.create
    else
      @invitation_code = InvitationCodeSuper.create(invitation_code_params)
    end

    redirect_to action: :index unless request.xhr?
  end

  private

  def invitation_code_params
    params.require(:invitation_code).permit(:super_user_id)
  end
end
