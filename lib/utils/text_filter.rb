require_relative "text_filter/dict"
require_relative "text_filter/cleaner"

module Caishuo::Utils
  module TextFilter
    class << self
      def clean(text, replace_str = "*")
        Cleaner.clean(text, replace_str)
      end

      def clean?(text)
        Cleaner.clean?(text)
      end

      def check(text)
        Cleaner.check(text)
      end
    end
  end
end