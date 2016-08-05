require 'api_detail'
module Trading
  
  class ApiComposite
    def initialize(api_details = [], account)
      #@user = ::UserBinding.find_by!(broker_user_id: account).get_binding_user
      @account = ::TradingAccount.find_by!(broker_no: account)
      @apis = api_details.map { |api| ApiDetail.new(api, @account) }
    end
    
    def reconcile
      log
      valid_apis.map(&:reconcile)
    end
    
    private
    def log
      @apis.map(&:create_api_order)
    end
    
    def valid_apis
      @apis.inject({}) { |res, api| res = api.valid? ? res.merge( api.order_id => api) : res }.try(:values)
    end
  end
  
end
