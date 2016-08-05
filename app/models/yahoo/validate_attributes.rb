require File.expand_path('../exception', __FILE__)

module Yahoo
  module ValidateAttributes
    extend ActiveSupport::Concern

    def self.included(base)
      base.send(:include, InstanceMethods)
    end

    module InstanceMethods
      def initialize(opts = {})
        case opts[:adj_close]
          when nil
            raise AdjCloseNilException.new(self)
          when 0.00
            raise AdjCloseZeroException.new(self)
          end
      end
    end
  end
end
