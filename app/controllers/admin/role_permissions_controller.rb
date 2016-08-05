class Admin::RolePermissionsController < Admin::ApplicationController
  
  def update_permission
    Admin::Role.find(params[:role_id]).permissions = Admin::Permission.where(id: params[:permission_id])
    redirect_to admin_roles_path
  end

  private
  def admin_role_permission_params
    params.require(:admin_role_permission).permit(:role_id, :permission_id)
  end
  
end