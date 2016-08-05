module Currency

  class Base
    attr_accessor :base_currency

    def initialize(base_currency)
      @base_currency = base_currency
    end

    def rate(currency)
      Currency::Cache.transform(currency, base_currency)
    end
  end

  # 单例调用
  class Cache
    include Singleton
    CURRENCIES = ["hkd", "usd", "cny", ""]

    CURRENCIES.product(CURRENCIES).each do |currency, base_currency|
      method_name = "#{currency}_to_#{base_currency}"
      define_method method_name do
        instance_variable_get("@#{method_name}") || instance_variable_set("@#{method_name}", Currency.send(method_name))
      end
    end

    def transform(currency, base_currency)
      send("#{currency.try(:downcase)}_to_#{base_currency.try(:downcase)}")
    end

    def self.transform(currency, base_currency)
      self.instance.transform(currency, base_currency)
    end

    def method_missing(method, *args, &block)
      method.match(/_to_/) ? 1 : (raise NoMethodError)
    end
  end

  def self.all_to_usd
    %w(cny hkd usd).map do |c|
      [c, send("#{c}_to_usd")]
    end.to_h.with_indifferent_access
  end

  # 当前港币对美元的汇率
  def self.hkd_to_usd
    $redis.hget(redis_key(__method__), 'last_trade_price_only').to_d
  end

  # 当前美元对港币的汇率
  def self.usd_to_hkd
    $redis.hget(redis_key(__method__), 'last_trade_price_only').to_d
  end

  def self.usd_to_cny
    $redis.hget(redis_key(__method__), 'last_trade_price_only').to_d
  end

  def self.cny_to_usd
    $redis.hget(redis_key(__method__), 'last_trade_price_only').try(:to_d)
  end

  def self.hkd_to_cny
    $redis.hget(redis_key(__method__), 'last_trade_price_only').to_d
  end

  def self.cny_to_hkd
    $redis.hget(redis_key(__method__), 'last_trade_price_only').to_d
  end

  class << self
    [:hkd, :usd].each do |currency|
      define_method "#{currency}_to_#{currency}" do
        1
      end
    end
  end

  def self.redis_key(name)
    "currency:#{name.to_s}"
  end

  def self.transform(currency, base_currency)
    # send("#{currency.try(:downcase)}_to_#{base_currency.try(:downcase)}")
    Currency::Cache.transform(currency, base_currency)
  end

  class << self
    def method_missing(method, *args, &block)
      method.match(/_to_/) ? 1 : (raise NoMethodError)
    end
  end

end
