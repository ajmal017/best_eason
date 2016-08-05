require 'detail_attrs'
module Trading
  
  class TwsDetail
    extend Forwardable
    
    def_delegators :exec_order, :processed?, :process!
    
    include InitHelper
    def initialize(options, account)
      super(options)
      @account = account
      @stock = ::BaseStock.find_by(ib_id: contract_id) || ::BaseStock.find_by!(ib_symbol: symbol)
    end
    
    def create_tws_order
      ::TwsExec.find_or_initialize_by(key_attrs).update(tws_attrs)
    end
    
    def exec_order
      @exec_order ||= ::ExecDetail.find_by(key_attrs)
    end
    
    private
    include DetailAttrs
    alias_method :tws_attrs, :shared_attrs
  end 
  
end
