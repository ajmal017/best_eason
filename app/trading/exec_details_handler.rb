require 'api_composite'
require 'tws_composite'
require 'commission_composite'

module Trading
  
  class ExecDetailsHandler
    
    def initialize(msg)
      @exec_details = msg
      @api_composite = ApiComposite.new(details[:api], account)
      @tws_composite = TwsComposite.new(details[:tws], account)
      @commission_composite = CommissionComposite.new(commissions)
    end
    
    def perform
      @api_composite.reconcile
      @tws_composite.reconcile
      @commission_composite.compute
    end
    
    private
    def account
      @exec_details["subAccount"]
    end
    
    def hash_details
      if @exec_details["exec"]["type"] == "API"
        api_details = [@exec_details["exec"]]
        tws_details = []
      else
        tws_details = [@exec_details["exec"]]
        api_details = []
      end
      [api_details, tws_details]
    end
    
    def array_details
      [array_api_details, array_tws_details]
    end
    
    def array_api_details
      @exec_details["exec"].select {|e| e["type"] == "API"}.inject([]) { |sum, detail| sum << detail }
    end
    
    def array_tws_details
      @exec_details["exec"].select {|e| e["type"] == "TWS"}.inject([]) { |sum, detail| sum << detail }
    end
    
    def details
      case @exec_details["exec"]
      when Array
        api_details, tws_details = array_details
      when Hash
        api_details, tws_details = hash_details
      else
        api_details, tws_details = [[],[]]
      end
      { api: api_details, tws: tws_details}
    end
    
    def commissions
      case @exec_details["commissionReport"]
      when Array
        array_commissions
      when Hash
        hash_commissions
      else
        []
      end
    end
    
    def array_commissions
      @exec_details["commissionReport"].inject([]) { |sum, com| sum << com }
    end
    
    def hash_commissions
      [@exec_details["commissionReport"]]
    end
    
  end
  
end
