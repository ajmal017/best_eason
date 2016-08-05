class Admin::UsersController < Admin::ApplicationController
  # load_and_authorize_resource 
  before_action :find_user, :only => [:set_company_user, :cancel_company_user, :reactivate, :blocked]

  def index
    @page_title = "注册用户列表"
    @provinces = CityInit.get_provinces[0]
    @cities = params[:q] ? CityInit.get_cities_by_province_code(params[:q][:province_eq]) : []
    @q = User.created_at_gte(params[:created_at_gteq]).created_at_lte(params[:created_at_lteq]).search(params[:q])
    @users = @q.result.order("id desc").paginate(page: params[:page] || 1, per_page: params[:per_page] || 20).to_a
  end
  
  def set_company_user
    @user.update_attribute(:is_company_user, true)
    render :text => "ok"
  end

  def search
    users = User.search_by(params[:term]).map{|u| u.attributes.slice("id", "username", "email")}
    render json: {users: users, term: params[:term]} 
  end

  def cancel_company_user
    @user.update_attribute(:is_company_user, false)
    render :text => "ok"
  end

  def data
    @page_title = "注册用户数据统计"
    @records = User.where(["created_at > ?", Date.today-30]).group("date(created_at)").count
  end

  # 重新发送激活邮件
  def reactivate
    @user.resend_confirmation_email
      
    render js: "alert('重新发送激活邮件成功!!!');window.location.reload();"
  end

  #  TODO 权限应该迁移到cancan
  def quick_login
    if current_admin_staffer and (current_admin_staffer.admin? or (params[:from] == 'majia'))
      sign_login_flag!(params[:id])
      redirect_to "/p/#{params[:id]}?from=admin"
    else
      redirect_to "/admin/users", notice: "权限错误"
    end
  end

  def blocked
    if @user.blocked?
      @user.normal!
    else
      @user.blocked!
      ApiToken.expire_all(@user.id)
    end
  end
  
  private
  def find_user
    @user = User.find(params[:id])
  end
end
