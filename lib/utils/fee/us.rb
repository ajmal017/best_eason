module Caishuo::Utils::Fee
  class Us
    attr_reader :price, :shares
    MIN_FEE = BigDecimal.new("2.99") # 每单（一只股票）交易最低费用
    SHARES_THRESHOLD = 300 #最低费用shares阀值
    PER_SHARE_FEE = BigDecimal.new("0.01") #gte阀值后每个share费用


    def initialize(opts = {})
      @price = opts[:price].to_f
      @shares = BigDecimal.new(opts[:shares].to_s)
    end

    def money
      [fee_by_shares, MIN_FEE].max
    end

    private

    def fee_by_shares
      shares * PER_SHARE_FEE
    end
  end
end