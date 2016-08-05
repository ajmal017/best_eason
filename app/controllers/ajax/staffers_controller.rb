class Ajax::StaffersController < Ajax::ApplicationController

  def check_email
    respond_to do |format|
      format.json do
        render json: !Admin::Staffer.where('lower(email) = ?', params[:admin_staffer][:email].downcase).where.not(id: params[:id]).exists?
      end
    end
  end
end
