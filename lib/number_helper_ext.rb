# 升级Rails需要注意此方法!!!
module ActiveSupport
  module NumberHelper
    class NumberToHumanConverter < NumberConverter
      # 增加万和亿单位
      DECIMAL_UNITS[4], DECIMAL_UNITS[8] = :wan, :yi
      INVERTED_DECIMAL_UNITS[:wan], INVERTED_DECIMAL_UNITS[:yi] = 4, 8
    end
  end
end
