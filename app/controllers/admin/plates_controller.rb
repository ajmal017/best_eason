class Admin::PlatesController < Admin::ApplicationController
  before_action :set_plate, only: [:show, :edit, :update, :destroy]

  def index
    @page_title = "财说板块列表"
    @q = Plate::Base.search(params[:q])
    @plates = @q.result.order(id: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page] || 20)
  end

  def show
  end

  def new
    @plate = Plate::Base.new
  end

  def edit
  end

  def create
    @plate = Plate::Base.new(plate_params)

    if @plate.save
      redirect_to [:admin, @plate], notice: 'Plate was successfully created.'
    else
      render :new
    end
  end

  def update
    if @plate.update(plate_params)
      redirect_to [:admin, @plate], notice: 'Plate was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @plate.destroy
    redirect_to admin_plates_url, notice: 'Plate was successfully destroyed.'
  end

  private
  
  def set_plate
    @plate = Plate::Base.find(params[:id])
  end

  def plate_params
    params.require(:plate).permit(:type, :market, :name, :base_stock_id, :symbol, :source_symbol, :start_on, :end_on, :status, :stocks_count, :update_time)
  end
end
