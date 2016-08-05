module Trading
  class PositionHandler
    include InitHelper

    def initialize(options)
      super(options)
      @stock = ::BaseStock.find_by(ib_id: contract_id) || ::BaseStock.find_by!(ib_symbol: symbol)
      @account = TradingAccount.find_by!(broker_no: account_name)
    end

    def perform
      pos = ::IbPosition.find_or_initialize_by(key_attrs)
      pos.update_attributes(other_attrs) if pos
    end

    def key_attrs
      {
        trading_account_id: @account.id,
        base_stock_id: @stock.id
      }
    end

    def other_attrs
      {
        symbol: symbol,
        exchange: exchange,
        contract_id: contract_id,
        account_name: account_name,
        position: position
      }
    end
  end
end
