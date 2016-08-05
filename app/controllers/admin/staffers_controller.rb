class Admin::StaffersController < Admin::ApplicationController
  # load_and_authorize_resource 

  def index
    @page_title = "管理员列表"
    @roles = Admin::Role.all
    @role = Admin::Role.find(params[:role_id]) if params[:role_id]
    @staffers = Admin::Staffer.includes(:role).order("id desc")
    @staffers = @staffers.where(role_id: @role.id) if @role
    @staffers = @staffers.where(deleted: true) if params[:tp] == "hidden"
    @staffers = @staffers.where(admin: true) if params[:sm] == "super_manager"
    @staffers = @staffers.paginate(page: params[:page] || 1, per_page: params[:per_page] || 20).to_a
  end

  def new
    @page_title = "添加管理员"
    @staffer = Admin::Staffer.new
  end

  def show
    @page_title = "管理员信息"
    @staffer = Admin::Staffer.find(params[:id])
  end

  def create
    @page_title = "添加管理员"
    @staffer = Admin::Staffer.new(admin_staffer_params)
    @staffer.username = params[:admin_staffer][:email] #添加管理员时用户名默认为用户注册邮箱
    if @staffer.save
      redirect_to admin_staffers_path, notice: "添加成功"
    else
      render :action => :new
    end
  end

  def edit
    @page_title = "修改管理员信息"
    @staffer = Admin::Staffer.find(params[:id])
  end

  def update
    @page_title = "修改管理员信息"
    @staffer = Admin::Staffer.find(params[:id])
    if @staffer.update(admin_staffer_params)
      if current_admin_staffer.username == @staffer.username
        sign_in(@staffer, :bypass => true)
      end
      redirect_to admin_staffers_path, notice: "修改成功"
    else
      render :action => :edit
    end
  end

  def destroy
    @staffer = Admin::Staffer.find(params[:id])
    @staffer.update(deleted: !@staffer.deleted, role_id: nil, admin: false)
    notice = @staffer.deleted ? '屏蔽成功！' : '解除屏蔽成功！'
    redirect_to(admin_staffers_url, :notice => "#{notice}  #{@staffer.email}")
  end
  
  private

  def admin_staffer_params
    params.require(:admin_staffer).permit(:username, :fullname, :email, :password, :password_confirmation, :admin, :role_id)    
  end
end
