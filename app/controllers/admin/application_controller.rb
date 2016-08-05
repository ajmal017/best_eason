class Admin::ApplicationController < ApplicationController
  # before_filter :authenticate_admin_staffer!
  before_filter :authenticate_admin!
  helper_method :sort_column, :sort_direction
  before_filter :current_staffer_permissions
  layout 'admin'
  
  private

  def load_locale
    I18n.locale = "zh-CN"
  end

  def authenticate_admin!
    redirect_to new_admin_staffer_session_path and return if current_admin_staffer.blank?
    sign_out(current_admin_staffer) and redirect_to new_admin_staffer_session_path and return if current_admin_staffer.deleted?
    render_403 and return if !current_admin_staffer.admin and current_admin_staffer.role_id.blank?
  end

  def current_staffer_permissions
    @per_hash = {}
    @current_user_permissions = current_admin_staffer.admin ? Admin::Permission.all : current_admin_staffer.permissions
    @current_user_permissions = @current_user_permissions.children.includes(:father).group_by {|cup| cup.father.try(:name) }
  end

  # cancan
  def current_ability
    @current_ability ||= Admin::Ability.new(current_admin_staffer)
  end

  rescue_from CanCan::AccessDenied do |exception|
    render :template => 'admin/shared/forbidden', :status => 403
  end

  def render_403
    render :template => 'admin/shared/forbidden', :status => 403
  end
  
  # 排序
  def sort_by_column
    "#{sort_column} #{sort_direction}"
  end

  def sort_column
    return params[:sort] if (controller_name.classify.constantize.column_names.include?(params[:sort])) || (params[:sort] =~ /\./ && 
      params[:sort].split('.').first.classify.constantize.attribute_names.include?(params[:sort].split('.').last))
    
    "id"
  end

  def sort_direction
    %w(asc desc).include?(params[:direction]) ? params[:direction] : "asc"
  end
end