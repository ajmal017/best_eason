class AdminController < ApplicationController
  layout false
  	
  def index
  end

  def new_blog
  	@tweet = Tweet.new
  end
end
