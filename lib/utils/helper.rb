module Caishuo::Utils
  class Helper

    class DefaultHelper
      include Singleton
      include ActiveSupport::NumberHelper
      include ActionView::Helpers::SanitizeHelper 
    end

    def self.helper
      DefaultHelper.instance
    end

    # Caishuo::Utils::Helper.number_to_delimited(100)
    def self.number_to_delimited(number, options = {})
      helper.number_to_delimited(number, options)
    end

    def self.number_to_rounded(number, options = {})
      helper.number_to_rounded(number, options)
    end

    def self.pretty_number(number, precision=2, strip_insignificant_zeros = true)
      number_to_rounded(number, precision: precision, significant: false, delimiter: ',', strip_insignificant_zeros: strip_insignificant_zeros)
    end

    # 百分比计算
    def self.div_percent(molecular, denominator, point=2)
      percent= molecular.fdiv(denominator) * 100
      (percent.infinite? || percent.nan?) ? 0 : percent.round(point)
    end

    def self.strip_links(html)
      helper.strip_links(html)
    end

  end
end
