class User::BaseController < ApplicationController
  before_filter :authenticate_user!
  before_action :set_menu
  
  private
  def set_menu
    @top_menu_tab = 'users'
  end
end
