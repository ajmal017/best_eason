module Spider
  class Item
    # attr_accessor :title, :content, :link, :publish_at, :remote_logo_url
    
    # def initialize(element)
    #   # @title = element.xpath("title").text.strip rescue ''
    #   # @content = element.xpath("description").text rescue ''
    #   # @remote_logo_url = Nokogiri::HTML(@content).css("img").first.attr("src") rescue '' if @content.present?
    #   # @remote_logo_url = nil if @remote_logo_url.present? and @remote_logo_url =~ /\.gif/
    #   # @link = element.xpath("link").text rescue ''
    #   # @publish_at = Time.parse(element.xpath("pubDate").text) rescue Time.now
    # end
    
    # def to_hash(attributes = {})
    #   # return instance_values if attributes.blank?
    #   # return instance_values.merge(attributes)
    # end
    

    def self.save(items)
      items.each_with_index do |item|
        next if ::ES::News.exists?(item[:id])
       
        ::ES::News.create(item) 
      end
    end

  end
end