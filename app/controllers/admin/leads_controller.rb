class Admin::LeadsController < Admin::ApplicationController
  before_action :load_lead, only: [:edit, :update, :show, :send_email, :edit_info, :update_info, :destroy]

  def index
    @page_title = "邀请人列表"
    @q = Lead.search(params[:q])
    @leads = @q.result.includes(:invitation_codes, :user, :landing).order(id: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page] || 20).to_a
  end

  def new
    @page_title = "添加邀请人"
    @lead = Lead.new
  end

  def create
    @page_title = "添加邀请人"
    @lead = Lead.new(lead_params)

    if @lead.save
      redirect_to admin_lead_path(@lead) and return
    else
      render :action => :new
    end
  end

  def show
    @page_title = "查看邀请人信息"
  end

  def edit
    @page_title = "设置邀请码页面"
  end

  def update
    @page_title = "修改邀请人"
    @invitation_code = InvitationCode.find_by(code: params[:lead][:code])
    if @invitation_code && @invitation_code.user_id.nil? && @invitation_code.lead.nil?
      @result = @invitation_code.update(lead_id: @lead.id)
    end
  end

  def edit_info
    @page_title = "修改邀请人信息"
  end

  def update_info
    @page_title = "修改邀请人信息"
    if @lead.update(lead_params)
      redirect_to admin_lead_path(@lead) and return
    else
      render action: :edit_info
    end
  end

  def send_email
    @result = @lead.send_invite_email
  end

  def multi_set
    Lead.multi_set_invitation_codes(params['lead_ids'].split(','))
    render json: true
  end

  def multi_send
    Lead.multi_set_invite_email(params['lead_ids'].split(','))
    render json: true
  end

  def import
    @imported_leads = Lead.import_with(params[:file])
  end

  def cancel_import
    Lead.where(id: params['lead_ids'].split(',')).delete_all
    render json: true
  end

  def destroy
    @lead.destroy

    redirect_to admin_leads_path
  end

  private
  
  def load_lead
    @lead = Lead.find(params[:id])
  end

  def lead_params
    params.require(:lead).permit(:username, :gender, :company, :mobile, :email, :weixin, :qq, :address, :invite_user_id, :source, :user_id)
  end
end
