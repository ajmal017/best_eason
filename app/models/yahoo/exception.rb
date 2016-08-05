class YahooFinanceException < Exception
end

class SymbolNotFoundException < YahooFinanceException
end

class AdjCloseNilException < YahooFinanceException
  def initialize(stock)
    $finance_logger.error(stock.symbol + " Adj_Close为空!!!")
    stock.retry
    super
  end
end

class AdjCloseZeroException < YahooFinanceException
  def initialize(stock)
    $finance_logger.error(stock.symbol + " Adj_Close为0!!!")
    stock.retry
    super
  end
end
