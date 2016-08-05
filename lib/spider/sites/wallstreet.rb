module Spider::Sites
  class Wallstreet < Base
    def url
      ::ES::Source.find_by(code: "wallstreet").url
    end

    def node_path
      
    end

    def items
      from_html.map do |item| 
        { 
          id: Base64.urlsafe_encode64(Digest::MD5.digest(item['href']))[0..-3],
          title: item.text.strip,
          url: item['href'],
          source: "wallstreet"
        }
      end
    end
    
    def from_html
      Nokogiri::HTML(@source).css(".news-list > li > .content > a")
    end
  end
end