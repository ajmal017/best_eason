class Ajax::ApplicationController < ApplicationController
  before_action :require_xhr?
  skip_after_filter :store_location
  layout false

  def require_xhr?
    render text: "Error Request" and return if Rails.env.production? and !request.xhr? and params[:force] != true
  end
end
