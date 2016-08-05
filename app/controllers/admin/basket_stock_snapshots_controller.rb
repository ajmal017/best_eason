class Admin::BasketStockSnapshotsController < Admin::ApplicationController
  before_action :set_basket_stock_snapshot, only: [:show, :edit, :update, :destroy]

  def index
    @q = BasketStockSnapshot.search(params[:q])
    @basket_stock_snapshots = @q.result.order(id: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page] || 20)
  end

  def show
  end

  def new
    @basket_stock_snapshot = BasketStockSnapshot.new
  end

  def edit
  end

  def create
    @basket_stock_snapshot = BasketStockSnapshot.new(basket_stock_snapshot_params)

    if @basket_stock_snapshot.save
      redirect_to [:admin, @basket_stock_snapshot], notice: 'Basket stock snapshot was successfully created.'
    else
      render :new
    end
  end

  def update
    if @basket_stock_snapshot.update(basket_stock_snapshot_params)
      redirect_to [:admin, @basket_stock_snapshot], notice: 'Basket stock snapshot was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @basket_stock_snapshot.destroy
    redirect_to admin_basket_stock_snapshots_url, notice: 'Basket stock snapshot was successfully destroyed.'
  end

  private
  
  def set_basket_stock_snapshot
    @basket_stock_snapshot = BasketStockSnapshot.find(params[:id])
  end

  def basket_stock_snapshot_params
    params.require(:basket_stock_snapshot).permit(:basket_id, :stock_id, :basket_adjustment_id, :weight, :stock_price, :change_percent, :next_basket_id, :notes, :adjusted_weight, :ori_weight)
  end
end
