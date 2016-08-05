require 'zhconv'
module Caishuo::Utils

  class Translate

    def self.convert(language='zh-cn', str)
      return '' if str.blank?
      ZhConv.convert(language.to_s, str, false) 
    end

    def self.tw(str)
      convert("zh-tw", str) 
    end

    def self.cn(str)
      convert("zh-cn", str) 
    end

  end

end