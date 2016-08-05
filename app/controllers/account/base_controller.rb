class Account::BaseController < ApplicationController
  layout 'application'
  
  before_filter :set_basic

  def set_basic
    #@background_color = 'white'
    #@require_site_search = false
  end

end
