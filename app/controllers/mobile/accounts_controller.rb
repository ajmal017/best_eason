class Mobile::AccountsController < Mobile::ApplicationController
  before_filter :authenticate_user!
  before_action :hide_gtm, :find_account
  before_action :get_type, only: [:compare_all, :compare_friends]

  layout 'mobile/common'

  def compare_all
    @page_title = "比一比 - 财说用户"
    @ranks = AccountRank.top_by(@account.broker_id, @type)
    @my_rank = AccountRank.where(trading_account_id: @account.id, rank_type: @type, user_id: current_user.id).first
    @ordered = @my_rank.ordered

    respond_to do |format|
      format.html
      format.json do
        datas = { user: {}, list: @ranks }
        datas[:user] = { vs: @account.ranking_percent(@type), percent: @my_rank.percent, change: @my_rank.profit } if @ordered
        render json: datas
      end
    end
  end

  def compare_friends
    @page_title = "比一比 - 我的好友"
    @ranks, @my_rank, @my_rankings, @prev_rank, @next_rank = AccountRank.compare_friends(current_user, @account, @type)

    respond_to do |format|
      format.html
      format.json do
        datas = { user: {}, list: @ranks }
        datas[:user][:prev] = @prev_rank ? { rank: @my_rankings - 1 }.merge(@prev_rank.pretty_json) : {}
        datas[:user][:cur] = { rank: @my_rankings }.merge(@my_rank.pretty_json)
        datas[:user][:next] = @next_rank ? { rank: @my_rankings + 1 }.merge(@next_rank.pretty_json) : {}
        render json: datas
      end
    end
  end

  def analysis
    @page_title = "投资分析"
    @year = params[:year] || Time.now.year
    @analysis = AccountAnalysis.find_by(trading_account_id: @account.id, year: @year) || AccountAnalysis.cal(@account, Date.today)

    respond_to do |format|
      format.html
      format.json do
        render json: @analysis.web_datas
      end
    end
  end

  private

  def find_account
    @account = TradingAccount.find_with_pretty_id(@current_user.id, params[:id])
    render text: "" and return unless @account
  end

  def get_type
    @type = AccountRank::RANK_TYPES.include?(params[:type]) ? params[:type] : AccountRank::RANK_TYPES.first
  end
end
