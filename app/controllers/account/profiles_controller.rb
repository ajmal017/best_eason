class Account::ProfilesController < Account::BaseController
  before_filter :authenticate_user!
  
  layout 'application'

  def new
    @new_user = session[:new_user]
    session.delete(:new_user)
    @profile = current_user.profile || current_user.create_profile
    @provinces, @cities = CityInit.get_provinces
    @user_cities = CityInit.get_cities_by_province_code(current_user.province)
  end
  
  def create
    current_user.update(user_params)
  end
  
  private
  
  def user_params
    if params[:user].present? and params[:user][:profile_attributes].present? 
      params[:user][:profile_attributes][:id] = current_user.profile.id
      params[:user][:profile_attributes][:taggings_attributes] = taggings_attributes if params[:profile] and params[:profile][:taggings_attributes].present?
    end
    params.require(:user).permit(:username, :headline, :province, :city, :gender, 
        profile_attributes: [:id, :province, :city, :gender, :duration, orientations: Profile::ORIENTATION.keys, concerns: Profile::CONCERN.keys, 
          taggings_attributes: [:tag_id, :taggable_id, :taggable_type]])
  end

  def taggings_attributes
    params[:profile][:taggings_attributes].transform_values { |x| x.merge(taggable_id: current_user.profile.id, taggable_type: "Profile") }
  end
  

end
