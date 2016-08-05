class Admin::BasketAdjustmentsController < Admin::ApplicationController
  before_action :set_basket_adjustment, only: [:show, :edit, :update, :destroy]

  def index
    @q = BasketAdjustment.search(params[:q])
    @basket_adjustments = @q.result.order(id: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page] || 20)
  end

  def show
  end

  def new
    @basket_adjustment = BasketAdjustment.new
  end

  def edit
  end

  def create
    @basket_adjustment = BasketAdjustment.new(basket_adjustment_params)

    if @basket_adjustment.save
      redirect_to [:admin, @basket_adjustment], notice: 'Basket adjustment was successfully created.'
    else
      render :new
    end
  end

  def update
    if @basket_adjustment.update(basket_adjustment_params)
      redirect_to [:admin, @basket_adjustment], notice: 'Basket adjustment was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @basket_adjustment.destroy
    redirect_to admin_basket_adjustments_url, notice: 'Basket adjustment was successfully destroyed.'
  end

  private
  
  def set_basket_adjustment
    @basket_adjustment = BasketAdjustment.find(params[:id])
  end

  def basket_adjustment_params
    params.require(:basket_adjustment).permit(:prev_basket_id, :next_basket_id, :original_basket_id, :reason, :date, :state)
  end
end
