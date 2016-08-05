module Trading
  
  module InitHelper
    
    def initialize(options, xml = nil)
      self.extend Hash[options.map {|k,v| [k.is_a?(Symbol) ? k : k.underscore.to_sym, v]}].to_module
      @xml = xml
    end
    
  end
  
end