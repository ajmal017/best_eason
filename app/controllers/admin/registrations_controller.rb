class Admin::RegistrationsController < Devise::RegistrationsController
  layout 'admin'
  def create
    build_resource(staffer_params)
    if resource.save
      if resource.active_for_authentication?
        set_flash_message :notice, :signed_up if is_navigational_format?
        sign_up(resource_name, resource)
        respond_with resource, :location => after_sign_up_path_for(resource)
      else
        set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_navigational_format?
        expire_session_data_after_sign_in!
        respond_with resource, :location => after_inactive_sign_up_path_for(resource)
      end
    else
      clean_up_passwords resource
      respond_with resource
    end
  end

  def edit
    @page_title = "修改密码"
  end
  
  def activate
    
  end
  
  private
  def staffer_params
    params.require(:admin_staffer).permit(:username, :email, :fullname, :password, :password_confirmation).merge(:username => params[:admin_staffer][:email])
  end
  
  protected
  def after_inactive_sign_up_path_for(resource)
    admin_activate_path(email: resource.email)
  end
  def after_sign_up_path_for(resource)
    admin_root_path
  end
  def after_update_path_for(resource)
    admin_root_path
  end
  
end
