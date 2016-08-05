module Textable
  extend ActiveSupport::Concern
  
  class Base
    
    def self.truncate_long_content(content, length)
      ActionController::Base.helpers.strip_tags(content).gsub(/(\r\n)|(\t)|(&radic;)|(&ldquo;)|(&rdquo;)|(&nbsp;)|(&#13;)|[　]+/i,'').truncate(length)
    end
    
    def self.md5(str)
      Digest::MD5.hexdigest(str)
    end

    def self.base64(str)
      Base64.encode64(str)
    end
  
  end
end
