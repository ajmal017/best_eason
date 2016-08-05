module TransformSymbol
  extend ActiveSupport::Concern

  def self.included(klass)
    klass.send :include, InstanceMethods
  end

  module InstanceMethods

    def set_yahoo_ticker
      self.ticker = Base.new(symbol).yahoo_ticker
    end

    def set_xignite_symbol
      self.xignite_symbol = XigniteBase.new(symbol).xignite_symbol
    end

  end

  class Base
    attr_accessor :symbol

    def initialize(symbol)
      @symbol = symbol
    end

    def yahoo_ticker
      ticker = %w(Hk Special Pr Blank Normal).each do |klass|
        adapter = "TransformSymbol::#{klass}".safe_constantize.new(symbol)
        break adapter.yahoo_ticker if adapter.unformat?
      end
    end
  end

  class XigniteBase
    attr_accessor :symbol

    def initialize(symbol)
      @symbol = symbol
    end

    def xignite_symbol

      result = %w(XigniteHk XigniteSpecial XignitePr XigniteBlank XigniteNormal).each do |klass|
        adapter = "TransformSymbol::#{klass}".safe_constantize.new(symbol)
        break adapter.xignite_symbol if adapter.unformat?
      end

      result
    end
  end

  class Hk < Base

    REGULAR = Regexp.new(/^\d{1,3}\.HK$/)

    def unformat?
      symbol.match(REGULAR)
    end

    def yahoo_ticker
      '0' * (7 - symbol.length) + symbol
    end

  end

  class Special < Base

    SYMBOLS = { 'DRE PRJCL' => 'DRE-PJ', 'CTZ PRACL' => 'CTZ-PA' }

    def unformat?
      SYMBOLS.key?(symbol)
    end

    def yahoo_ticker
      SYMBOLS[symbol]
    end

  end

  class Pr < Base

    REGULAR = Regexp.new(/ PR\w{0,1}$/)

    def unformat?
      symbol.match(REGULAR)
    end

    def yahoo_ticker
      symbol.gsub(' PR', '-P')
    end

  end

  class Blank < Base

    REGULAR = Regexp.new(/ /)

    def unformat?
      symbol.match(REGULAR)
    end

    def yahoo_ticker
      symbol.gsub(REGULAR,'-')
    end

  end

  class Normal < Base
    def unformat?
      true
    end

    def yahoo_ticker
      symbol
    end
  end

  class XigniteHk < XigniteBase
    def unformat?
      symbol =~ /HK$/
    end

    def xignite_symbol
      symbol.gsub(/\.HK$/, '.XHKG')
    end
  end

  class XigniteSpecial < XigniteBase
    SYMBOLS = { 'DRE PRJCL' => 'DRE/PJ', 'CTZ PRACL' => 'CTZ/PA' }

    def unformat?
      SYMBOLS.key?(symbol)
    end

    def xignite_symbol
      SYMBOLS[symbol]
    end
  end

  class XignitePr < XigniteBase
    REGULAR = Regexp.new(/ PR\w{0,1}$/)

    def unformat?
      symbol.match(REGULAR)
    end

    def xignite_symbol
      symbol.gsub(' PR', '/P')
    end
  end

  class XigniteBlank < XigniteBase
    REGULAR = Regexp.new(/ /)

    def unformat?
      symbol.match(REGULAR)
    end

    def xignite_symbol
      symbol.gsub(REGULAR,'/')
    end
  end

  class XigniteNormal < XigniteBase
    def unformat?
      true
    end

    def xignite_symbol
      symbol
    end
  end

end
