require 'commission'
module Trading
  
  class CommissionComposite
    
    def initialize(commissions = [])
      @commissions = commissions.map { |com| Commission.new(com) }
    end
    
    def compute
      log
      @commissions.reject { |com| com.processed? }.map(&:compute)
    end
    
    private
    def log
      @commissions.map(&:create_commission)
    end
    
  end
  
end