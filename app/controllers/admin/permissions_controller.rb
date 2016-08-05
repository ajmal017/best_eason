class Admin::PermissionsController < Admin::ApplicationController

  #before_action :get_father_permissions, only: [:new, :edit, :index, :show_permission_by_role]
  before_action :get_permission, only: [:edit, :ajax_delete_permission, :update]
  before_action :get_staffers, only: [:new, :edit, :create, :update]

  def index
    @father_permissions ||= Admin::Permission.father.includes(:roles,:childrens)
    @fathers = Admin::Permission.father.pluck(:id)
  end

  def new
    @permission = Admin::Permission.new
    @father_permissions ||= Admin::Permission.father
    $father_temp = params[:father_id]
  end

  def edit
    @father_permissions ||= Admin::Permission.father
  end

  def update
    @father_permissions ||= Admin::Permission.father
    if @permission.update_attributes(admin_permission_params)
      redirect_to admin_permissions_path
    else
      render :new
    end
  end

  def create
    @error = ""
    @father_permissions ||= Admin::Permission.father
    @permission = Admin::Permission.new(admin_permission_params)
    if params[:permission] == nil
      if !@permission.save
        @error = "请选择权限类别！"
        render :new
      else
        redirect_to admin_permissions_path
      end
    else
      if (params[:permission][:father_id] == "father")
        @permission.url = "###"
      end
      if @permission.save
        redirect_to admin_permissions_path
      elsif
        render :new
      end
    end
  end

  def ajax_delete_permission
    status, msg = false, nil
    if @permission.childrens.count.zero?
      @permission.destroy
      status = true
    else
      msg = "此权限下有二级权限暂时不能删除！"
    end
    render json: {status: status, msg: msg}
  end

  def update_permission_by_role
    @roles = Admin::Role.all
  end

  def show_permission_by_role
    @role = Admin::Role.find(params[:role_id])
    @father_permissions ||= Admin::Permission.father.includes(:childrens)
    @current_role_permissions_id = @role.permissions.pluck(:permission_id)
  end

  private
  def admin_permission_params
    params.require(:admin_permission).permit(:name, :url, :father_id, :staffer_id)
  end

  def get_staffers
    @staffers = Admin::Staffer.where("admin = 1 or role_id in (?)",Admin::Role.where(name: "Ruby开发").pluck(:id))
  end

  def get_permission
    @permission ||= Admin::Permission.find(params[:id])
  end

end