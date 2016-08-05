module TradingAccountHelper
  BROKER_NAMES = { "ib" => "yingtou", "unicorn" => "yiqun", "citics" => "zhongxin", "icitics" => "zhongxin" }

  def broker_logo_name(broker_name)
    BROKER_NAMES[broker_name]
  end

  def account_auditing_class(account)
    case 
    when account.auditing?
      "pending"
    when account.audited? || account.unaudited? 
      "active"
    end
  end

  def account_auditing_name(account)
    case 
    when account.auditing?
      "审核中"
    when account.audited?
      "审核通过"
    when account.unaudited?
      "审核未通过"
    end
  end

  def account_auditing_days(account)
    account.is_a?(TradingAccountEmail) ? 5 : 1    
  end

  def account_status_name(status)
    return "绑定中" if TradingAccount::STATUS.values_at(:new, :audited, :unaudited).include?(status)
    
    case status
    when TradingAccount::STATUS[:normal]
      "绑定"
    when TradingAccount::STATUS[:recert]
      "失效"
    end
  end

  def account_status_class(status)
    return "mins" if TradingAccount::STATUS.values_at(:new, :audited, :unaudited).include?(status)
    
    case status
    when TradingAccount::STATUS[:recert]
      "plus"
    else
      ""
    end
  end

  # 账号绑定form的id
  def account_bind_form_id(broker)
    return "authZhongxin" if broker.market == "cn"

    "#{broker.name}_bind_form" 
  end
end
