class Admin::FeaturedBasketsController < Admin::ApplicationController
  def index
    @page_title = "精选组合"
    @featured_baskets = FeaturedBasket.all
  end

  def update_all
    params[:featured_basket].each do |p|
      FeaturedBasket.new(p).save
    end
    redirect_to "/admin/featured_baskets"
  end

  def edit_all
    @page_title = "修改精选组合"
    @featured_baskets = FeaturedBasket.all
  end

end
