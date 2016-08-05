class Admin::PlayersController < Admin::ApplicationController
  before_action :set_player, only: [:show, :edit, :update, :destroy, :login]

  def index
    @q = Player.includes(:trading_account, :contest, :user).search(params[:q])
    @players = @q.result.order(id: :desc)
    if params[:pt_data_error]
      @players = @players.select{|player| player.pt_data_error? }
    end
    @players = @players.paginate(page: params[:page] || 1, per_page: params[:per_page] || 20)
  end

  def show
  end

  def new
    @player = Player.new
  end

  def edit
  end

  def create
    @player = Player.new(player_params)

    if @player.save
      redirect_to [:admin, @player], notice: '选手已创建.'
    else
      render :new
    end
  end

  def update
    if @player.update(player_params)
      redirect_to [:admin, @player], notice: '选手已更新.'
    else
      render :edit
    end
  end

  def login
    Resque.enqueue(PTLoginWorker, @player.trading_account_id)
    # TradingAccount.find(@player.trading_account_id).login('tac123456')
    redirect_to admin_players_url
  end

  def destroy
    @player.destroy
    redirect_to admin_players_url, notice: '选手已删除.'
  end

  def cash
    @players = Player.all
  end

  private
  
  def set_player
    @player = Player.find(params[:id])
  end

  def player_params
    params.require(:player).permit(:user_id, :contest_id, :original_money, :status, :trading_account_id)
  end
end
