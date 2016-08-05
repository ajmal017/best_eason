class Events::ShipandasaiController < ApplicationController
  layout 'events'
  before_action :authenticate_user!, except: [:index]
  before_action :set_page_title
  def index
    @no_scale = true
  end

  def new
    @pt_app = current_user.pt_application || current_user.build_pt_application
    redirect_to edit_events_shipandasai_path(id: current_user.id) if @pt_app.approved?
    @old_record = current_user.pt_application.id
  end

  def create
    if @pt_app = current_user.pt_application
      @old_record = true
    else
      @pt_app = current_user.create_pt_application(pt_params)
      @pt_app.save if Sms.verifty(pt_params[:mobile], pt_params[:captcha])
    end
    render 'new'
  end

  def edit
    @pt_app = current_user.pt_application
    redirect_to new_events_shipandasai_path unless @pt_app && @pt_app.approved?
  end

  def update
    @pt_app = current_user.pt_application
    if @pt_app.current_step == 2 or @pt_app.update(pt_params.merge(current_step: 2))
      redirect_to root_path
    else
      render :edit
    end
  end

private

  def set_page_title
    @page_title = '财说首届实盘炒股大赛'
  end

  def pt_params
    params[:pt_application].permit(:mobile, :q1, :q2, :q3, {q4: []}, :q5, :q6, :q7, :q8, :q9, :name, :id_no, :industry, :com_name, :bank_name, :card_no)
  end
end
