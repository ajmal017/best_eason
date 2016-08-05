class TradingAccountP2p < TradingAccount

  def category_name
    "P2P账号"
  end

  def format_json
    {
      pretty_id: pretty_id,
    }.merge remote_profile
  end

  def total_property
    remote_profile[:total_asset].to_f
  end

  def today_profit
    0
  end

  def remote_profile
    @remote_profile ||= P2pService.user_profile(self.user)[0]
  end

end
