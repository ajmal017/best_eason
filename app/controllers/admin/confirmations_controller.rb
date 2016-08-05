class Admin::ConfirmationsController < Devise::ConfirmationsController
  layout 'admin'
  def create
    self.resource = resource_class.send_confirmation_instructions(resource_params)
    successfully_sent?(resource)
    notice_message(resource.errors[:email].first) if resource.errors.any?
    respond_with({}, :location => after_resending_confirmation_instructions_path_for(resource_name))
  end

  def change_email
    @staffer = Admin::Staffer.find_by(email: params[:admin_staffer][:email])
    if @staffer && @valid_password = @staffer.valid_password?(params[:admin_staffer][:password])
      @staffer.update(email: params[:admin_staffer][:new_email]) && @staffer.update_column(:email, params[:admin_staffer][:new_email])
    end
  end

  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])

    if resource.errors.empty?
      if Devise.allow_insecure_sign_in_after_confirmation
        session[:new_user] = true
        set_flash_message(:notice, :confirmed_and_signed_in) if is_navigational_format?
        sign_in(resource_name, resource)
        
      else
        set_flash_message(:notice, :confirmed) if is_navigational_format?
      end
      respond_with_navigational(resource){ redirect_to after_confirmation_path_for(resource_name, resource) }
    else
      render :failure
    end
  end

  protected 

  def devise_i18n_options(options)
    options[:scope] = "devise.#{self.class.superclass.controller_name}"
    options[:resource_name] = nil
    options
  end

  def notice_message(message)
    flash[:notice] = message
  end

  def after_resending_confirmation_instructions_path_for(resource_params)
    admin_activate_path(email: self.resource.email, from: 'resend')
  end

  private

  def after_confirmation_path_for(resource_name, resource)
    admin_base_stocks_path
  end
end
