module Trading
  
  module AckHelper
    
    def success!
      ack!
    end

    def drop!
      ack!
    end

    def to_dead_letter!
      reject!
    end
    
  end
  
end