module Weixin
  class Message
    def initialize(messages_hash)
      @messages = messages_hash
    end

    # 处理消息（记录等），如需返回消息则拼装返回消息
    def process
      ""
    end

  	#微信消息示例：
    #  详见：http://mp.weixin.qq.com/wiki/index.php?title=%E6%8E%A5%E6%94%B6%E6%99%AE%E9%80%9A%E6%B6%88%E6%81%AF
    #
    def self.factory(xml_str)
      messages_hash = xml_to_hash(xml_str)
      message = case messages_hash["MsgType"]
        when "text"
          then TextMessage.new(messages_hash)
        when "event"
      	  then EventMessage.new(messages_hash)
        else
          #raise ArgumentError, 'not support Message, need to add'
          Message.new(messages_hash)
        end
      message
    end

    def self.xml_to_hash(xml_str)
      doc = Nokogiri::XML(xml_str)
      datas_arr = doc.xpath("/xml").children.map{|x| [x.name, x.text]}
      Hash[datas_arr]
    end
  end

  class TextMessage < Message
    def process
      #todo
    end
  end

  class EventMessage < Message
    def process
      #todo
    end
  end
end