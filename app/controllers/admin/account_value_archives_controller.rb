class Admin::AccountValueArchivesController < Admin::ApplicationController
  before_action :set_account_value_archive, only: [:show, :edit, :update, :destroy]

  def index
    @q = AccountValueArchive.search(params[:q])
    @account_value_archives = @q.result.order(id: :desc).paginate(page: params[:page] || 1, per_page: params[:per_page] || 20)
  end

  def show
  end

  def new
    @account_value_archive = AccountValueArchive.new
  end

  def edit
  end

  def create
    @account_value_archive = AccountValueArchive.new(account_value_archive_params)

    if @account_value_archive.save
      redirect_to [:admin, @account_value_archive], notice: 'Account value archive was successfully created.'
    else
      render :new
    end
  end

  def update
    if @account_value_archive.update(account_value_archive_params)
      redirect_to [:admin, @account_value_archive], notice: 'Account value archive was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @account_value_archive.destroy
    redirect_to admin_account_value_archives_url, notice: 'Account value archive was successfully destroyed.'
  end

  private
  
  def set_account_value_archive
    @account_value_archive = AccountValueArchive.find(params[:id])
  end

  def account_value_archive_params
    params.require(:account_value_archive).permit(:user_id, :broker_user_id, :key, :currency, :value, :user_binding_id, :archive_date, :base_currency, :trading_account_id)
  end
end
