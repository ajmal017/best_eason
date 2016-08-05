class UserBindingsController < ApplicationController
  before_filter :authenticate_user!

  before_action :load_user_binding, only: [:destroy]

  def destroy
    @user_binding.destroy

    redirect_to brokers_users_path
  end

  private

  def load_user_binding
    @user_binding = UserBinding.find(params[:id])
  end
end
