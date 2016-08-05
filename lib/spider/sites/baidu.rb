module Spider::Sites
  class Baidu < Base
    def url
      ::ES::Source.find_by(code: "baidu").url
    end

    def node_path
      
    end

    def items
      from_xml.map do |item| 
        xml_item(item)
      end.reject {|x| x[:source].blank? && x[:description].blank? && x[:author].blank? }
    end

    def xml_item(item)
      { 
        id: Base64.urlsafe_encode64(Digest::MD5.digest(item.css('link').text))[0..-3],
        title: item.css('title').text.strip,
        url: item.css('link').text,
        source: item.css('source').text,
        body: item.css('description').text,
        pub_date: item.css('pubDate').text,
        author: item.css('author').text
      }
    end
    
    def from_xml
      Nokogiri::XML(@source).xpath("//item")
    end
  end
end

