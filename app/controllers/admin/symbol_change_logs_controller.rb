class Admin::SymbolChangeLogsController < Admin::ApplicationController

  before_action :set_symbol_change_log, only: [:show, :edit, :update, :destroy]
  before_action :get_stock, only: [:index]

  def index
    @q = SymbolChangeLog.search(params[:q])
    @symbol_change_logs = @q.result.order(id: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page] || 20)
  end

  def show
  end

  def new
    @symbol_change_log = SymbolChangeLog.new
  end

  def edit
  end

  def create
    @symbol_change_log = SymbolChangeLog.new(symbol_change_log_params)

    if @symbol_change_log.save
      redirect_to [:admin, @symbol_change_log], notice: 'Symbol change log was successfully created.'
    else
      render :new
    end
  end

  def update
    if @symbol_change_log.update(symbol_change_log_params)
      redirect_to [:admin, @symbol_change_log], notice: 'Symbol change log was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @symbol_change_log.destroy
    redirect_to admin_symbol_change_logs_url, notice: 'Symbol change log was successfully destroyed.'
  end

  private
  
  def set_symbol_change_log
    @symbol_change_log = SymbolChangeLog.find(params[:id])
  end

  def get_stock
    p "symbol"
    @stock = params[:q].present? && params[:q][:base_stock_id_eq].present? ? BaseStock.where(id: params[:q][:base_stock_id_eq]).pluck(:id, :name).flatten : []
  end

  def symbol_change_log_params
    params.require(:symbol_change_log).permit(:base_stock_id, :field, :log, :log_type)
  end
end
