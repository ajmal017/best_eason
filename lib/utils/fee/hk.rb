module Caishuo::Utils::Fee
  # hk按照交易费取百分比，所有种类费用相加
  class Hk
    attr_reader :price, :shares, :cost

    # ib费用
    MIN_IB_FEE = BigDecimal.new("30") # 每单（一只股票）交易ib最低费用
    PER_SHARE_FEE_RATIO = BigDecimal.new("0.001") # ib费用：交易额乘以此比例，低于MIN_IB_FEE取MIN_IB_FEE

    # 交易所费用：0.005%交易值 + hkd 0.50每笔交易
    EXCHANGE_FLOAT_FEE_RATIO = BigDecimal.new("0.00005")
    EXCHANGE_FIX_FEE_PER_TRANSACTION = BigDecimal.new("0.5")

    # 结算费用：0.002%交易值，最低hkd 2.00每笔交易
    SETTLEMENT_FEE_RATIO = BigDecimal.new("0.00002")
    SETTLEMENT_MIN_FEE = BigDecimal.new("2")

    # 转让费用：
    #    印花税：0.1%（向上进位至1.00）将转收股票执行费用
    STAMP_FEE_RATIO = BigDecimal.new("0.001")
    #    SFC交易税款：0.0027% will be passed on 股票和权证 executions
    SFC_FEE_RATIO = BigDecimal.new("0.000027")

    def initialize(opts = {})
      @price = BigDecimal.new(opts[:price].to_s)
      @shares = BigDecimal.new(opts[:shares].to_s)
      @cost = @price * @shares
    end

    def money
      ib_fee + exchange_fee + settlement_fee + stamp_fee + sfc_fee
    end

    private

    def ib_fee
      fee = cost * PER_SHARE_FEE_RATIO
      [fee, MIN_IB_FEE].max
    end

    def exchange_fee
      float_fee = cost * EXCHANGE_FLOAT_FEE_RATIO
      float_fee + EXCHANGE_FIX_FEE_PER_TRANSACTION
    end

    def settlement_fee
      fee = cost * SETTLEMENT_FEE_RATIO
      [fee, SETTLEMENT_MIN_FEE].max
    end

    def stamp_fee
      (cost * STAMP_FEE_RATIO).ceil
    end

    def sfc_fee
      cost * SFC_FEE_RATIO
    end
  end
end