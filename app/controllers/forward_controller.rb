class ForwardController < ApplicationController

  def index
    if request_user?  
      user = User.find_by(username: params[:name])
      if user
        redirect_to profile_path(user) and return
      end
    elsif request_stock?
      base_stock = BaseStock.find_by(c_name: params[:name])
      if base_stock
        redirect_to stock_path(base_stock) and return
      end
    end

    redirect_to baskets_path("search[search_word]" => params[:name])
  end
  
  private

  def request_user?
    request.path =~ /^\/u\//
  end

  def request_stock?
    request.path =~ /^\/s\//
  end
end


