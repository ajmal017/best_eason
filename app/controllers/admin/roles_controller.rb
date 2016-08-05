class Admin::RolesController < Admin::ApplicationController
  #load_and_authorize_resource

  before_action :get_role, only: [:edit, :ajax_delete_role, :update]

  def index
    @roles = Admin::Role.all.paginate(page: params[:page] || 1, per_page: params[:per_page] || 10)
  end

  def show
  end

  def new
    @role = Admin::Role.new
  end

  def edit
  end

  def create
    @role = Admin::Role.new(admin_role_params)
    if @role.save
      redirect_to admin_roles_path
    else
      render :new
    end
  end

  def update
    if @role.update_attributes(admin_role_params)
      redirect_to admin_roles_path
    else
      render :new
    end
  end

  def ajax_delete_role
    status, msg = false, nil
    if @role.staffers.count.zero?
      @role.destroy
      status = true
    else
      msg = "此角色有其它管理员管理暂时不能删除！"
    end
    render json: {status: status, msg: msg}
  end

  private
  def admin_role_params
    params.require(:admin_role).permit(:name)
  end

  def get_role
    @role = Admin::Role.find(params[:id])
  end
end