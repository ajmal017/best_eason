class Admin::IbIdChangeLogsController < Admin::ApplicationController
  before_action :set_ib_id_change_log, only: [:show, :edit, :update, :destroy]

  def index
    @q = IbIdChangeLog.search(params[:q])
    @ib_id_change_logs = @q.result.order(id: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page] || 20)
  end

  def show
  end

  def new
    @ib_id_change_log = IbIdChangeLog.new
  end

  def edit
  end

  def create
    @ib_id_change_log = IbIdChangeLog.new(ib_id_change_log_params)

    if @ib_id_change_log.save
      redirect_to [:admin, @ib_id_change_log], notice: 'Ib id change log was successfully created.'
    else
      render :new
    end
  end

  def update
    if @ib_id_change_log.update(ib_id_change_log_params)
      redirect_to [:admin, @ib_id_change_log], notice: 'Ib id change log was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @ib_id_change_log.destroy
    redirect_to admin_ib_id_change_logs_url, notice: 'Ib id change log was successfully destroyed.'
  end

  private
  
  def set_ib_id_change_log
    @ib_id_change_log = IbIdChangeLog.find(params[:id])
  end

  def ib_id_change_log_params
    params.require(:ib_id_change_log).permit(:symbol, :ib_id, :date)
  end
end
