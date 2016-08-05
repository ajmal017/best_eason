class LandingsController < ApplicationController
  layout false

  def index
    @landing = Landing.new
  end

  def list
  end

  def create
    @landing = Landing.new(landing_params.merge(request_ip: request.remote_ip))
    
    UserMailer.landing(@landing.id).deliver if @landing.save
  end
  
  def succ
  end

  private
  
  def landing_params
    params.require(:landing).permit(:email)
  end
end
