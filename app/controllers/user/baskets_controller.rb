class User::BasketsController < User::BaseController
  def index
    @basket_follows = Follow::Basket.followed_baskets_by(current_user.id).paginate(:page => params[:page] || 1, :per_page => 10)
    @top_menu_tab = "following"
    @sub_menu_tab = 'basket'
    @background_color = "white"
  end
end
