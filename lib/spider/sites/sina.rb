module Spider::Sites
  class Sina < Base

    def url
      ::ES::Source.find_by(code: "sina").url
    end

    def node_path
      /,(title[^}]*)/
    end

    def items
      return @items if @nodes.present?
      @items = ExecJS.eval("[#{(source.scan(node_path).flatten.map{|str| "{#{str}}"} * ",").gsub(/ : /, ':')}]").map{|item| item[:id]=Base64.urlsafe_encode64(Digest::MD5.digest(item['url']))[0..-3];item[:source]="sina";item}
    end

    def source=(new_source)
      @source = new_source.encode('utf-8','gbk')
    end

    def format
      :json
    end

  end
end