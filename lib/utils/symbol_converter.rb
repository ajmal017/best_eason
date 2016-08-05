module Caishuo::Utils

  class SymbolConverter

    class << self

      # qq to caishuo
      def to_caishuo(symbol)
        market = symbol.first(2).downcase
        case market
        when *["sz", "sh"]
          "#{symbol.last(6)}.#{market}"
        when "hk"
          /hk0*(.*)/.match symbol
          "#{$1}.hk"
        when "us"
          symbol[2..-1]
        else
          ""
        end
      end

      # caishuo to qq
      def cs_to_zxg(symbol, market)
        case market.to_s
        when "cn"
          symbol.split(".").reverse.join.downcase
        when "hk"
          "hk#{symbol.split(".").first.rjust(5, "0")}"
        when "us"
          "us#{symbol}".downcase
        end
      end


    end

  end

end