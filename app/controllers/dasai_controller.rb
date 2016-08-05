class DasaiController < ApplicationController
  layout false

  def index
    @members_count = BasketRank.contest_1_count
    @scores = BasketRank.contest_1_top(50)
    if @scores.present?
      @baskets = Basket.where(id: @scores.keys).select("baskets.id, baskets.title, users.username").joins(:author).order("field(baskets.id,#{@scores.keys * ","})").to_a
      @top_basket = Basket.find(@baskets.shift.id)
    else
      @baskets = []
    end
    @scores = @scores.delete_if{|k,v| v==0}
  end
end
