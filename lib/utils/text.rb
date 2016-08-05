module Caishuo::Utils
  class Text

    def self.truncate_long_content(content, length)
      ActionController::Base.helpers.strip_tags(content).gsub(/(\r\n)|(\t)|(&radic;)|(&ldquo;)|(&rdquo;)|(&nbsp;)|(&#13;)|[　]+/i,'').truncate(length)
    end

    # 截取评论的内容(text是原始文本)
    def self.truncate_body(text, length = 100, omission = "...")
      short_text = truncate_long_content(text, length)
      str = truncate_emoji_text(truncate_stock_text(truncate_mention_text(short_text)))
      (short_text.end_with?(omission) && !str.end_with?(omission)) ? (str + omission) : str
    end

    # 截取完整的@符号
    def self.truncate_mention_text(text, length = 100)
      rindex = text.rindex("@")
      return text if rindex.nil? || text[rindex..-1] =~ / /
      
      text.size < length ? text : text[0, rindex]
    end

    # 截取完整的$符号
    def self.truncate_stock_text(text)
      return text if text.count("$").even?

      text[0..text.rindex("$").pred]
    end

    # 截取完整的emoji符号
    def self.truncate_emoji_text(text)
      return text if text.count("[") == text.count("]")
      
      rindex = text.rindex("[")
      rindex ? text[0, rindex] : text
    end

    def self.md5(str)
      Digest::MD5.hexdigest(str)
    end

    def self.base64(str)
      Base64.encode64(str)
    end

    # 自动转换@以及$股票等等
    def self.auto_link_text(text)
      replace_emoji auto_link_stocks(auto_link_usernames(text)).html_safe
    end

    def self.auto_link_usernames(text)
      text.gsub(/@[^\s|^@]+/) do |username|
        user = User.find_by(username: username.sub('@', ''))
        user.blank? ? username : %(<a href="/p/#{user.id}" class="j_bop" data-uid="#{user.id}"><mark>#{username} </mark></a>)
      end
    end

    def self.auto_link_stocks(text)
      text.gsub(/\$(.*?)\$/) do |name|
        s = BaseStock.find_by(symbol: (name.scan /\((\S*)\)/).flatten.first)
        s.present? ? %(<a href='/stocks/#{s.id}' class='j_bop' data-sid='#{s.id}'><mark>#{name} </mark></a>) : name
      end
    end

    EMOTIONS_ALL = YAML.load_file(Rails.root.join("data", "emotions.yml"))
    EMOTIONS_FACE = EMOTIONS_ALL["face"]
    EMOTIONS_EMOJI = EMOTIONS_ALL["emoji"]
    
    EMOTIONS_MAPPING = EMOTIONS_FACE.merge(EMOTIONS_EMOJI)
    EMOTIONS_REGEX = /#{EMOTIONS_MAPPING.keys.map{|e| e.sub('[', '\[').sub(']', '\]')} * "|"}/
    EMOTIONS_PATH = "#{Setting.cdn_host}/images/emotions/"


    # /images/emotions/emoji/xxxx
    def self.replace_emoji(string)
      return string unless string

      safe_string = safe_string(string.dup)
      safe_string.gsub!(EMOTIONS_REGEX) do |moji|
        %Q{<img src="#{EMOTIONS_PATH}#{EMOTIONS_MAPPING[moji]}" title="#{moji}" class="emo">}
      end
      safe_string = safe_string.html_safe if safe_string.respond_to?(:html_safe)
      safe_string
    end

    def self.safe_string(string)
      if string.respond_to?(:html_safe?) && string.html_safe?
        string
      else
        escape_html(string)
      end
    end

    def self.escape_html(string)
      escaper = defined?(EscapeUtils) ? EscapeUtils : CGI
      escaper.escape_html(string)
    end


  end
end
