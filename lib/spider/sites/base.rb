require 'digest/md5'
module Spider::Sites
  class Base
    attr_accessor :url, :items, :source # , :response

    def initialize
      self.source = Spider::Crawler.new(url).body
      save_to_db
    end

    # protected
    def url
      raise Spider::MissAttributesError, "missing attribute #{self.class}#url"
    end

    # item的xpath
    def node_path
      raise Spider::MissAttributesError, "missing attribute #{self.class}#node_path"
    end

    def to_hash
      nodes
    end

    def save_to_db
      Spider::Item.save(items) if items.present?
    end


  end
end