# snapshot
class Mobile::Shares::SnapshotsController < Mobile::ApplicationController
  layout "mobile/basic"

  caches_page :account, :account_analysis

  before_action :decode_param, only: [:account, :account_analysis]

  def account
    account_id, type, _other = @params_str.split("_")
    account = TradingAccount.find_by_pretty_id(account_id).try(:first)
    ranks = AccountRank.includes(:broker).where(trading_account_id: account.id).map {|x| [x.rank_type, x]}.to_h
    user = ranks.values.first.user
    date = ClosedDay.get_work_day(Date.today, :cn).to_s(:db)
    @datas = {
      date: date,
      name: user.username,
      avatar: user.avatar_url(:large),
      vs: account.ranking_percent(type),
      type: type,
      change: ranks[type].profit,
      percent_day: ranks["day"].percent,
      percent_month: ranks["month"].percent,
      percent_total: ranks["total"].percent,
      win_rate_avg: account.win_rate
    }
    @page_title = account_title(@datas[:change], type)
  end

  def account_analysis
    @page_title = "财说对我的投资分析的头头是道，你也来看看呗！"
    account_id, @year, _other = @params_str.split("_")
    @account = TradingAccount.find_by_pretty_id(account_id).try(:first)
    @analysis = AccountAnalysis.find_by(trading_account_id: @account.id, year: @year) || AccountAnalysis.cal(@account, Date.today)
    render "mobile/accounts/analysis", layout: "mobile/common"
  end

  private

  def decode_param
    @params_str = Caishuo::Utils::Encryption::UrlSafe.decode(params[:encoded_params].to_s)
  end

  def account_title(change, type)
    period = { day: "今天", month: "近一月", total: "" }.with_indifferent_access[type]
    if change > 0
      "我#{period}炒股赚了#{change}元，so easy！快去财说关注我，带你赚钱带你飞！"
    else
      "妈蛋！我#{period}炒股赔了#{change.abs}元 :( 入市虽易，赚钱不易，还是先在模拟盘练练手吧！"
    end
  end
end
