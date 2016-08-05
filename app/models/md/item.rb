module MD

  class Item
    include Mongoid::Document
    embedded_in :feed, class_name: "MD::Feed"

    field :type
    field :name
    field :user_id, type: Integer
    field :url
    field :source
    field :category  # 学院、博客、头条、等等
    field :tags, type: Array, default: []  # 标签，概念股、机器人
    field :ext_data, type: Hash, default: {}


    attr_accessor :data

    def data
      @data ||= init_data
    end
    # 初始化Data
    def init_data
    end

    def item_type
      self.class.name.gsub("MD::Item", '').downcase
    end


    def pretty_json
      {
        id: _id.to_s,
        type: item_type,
        name: name,
        url: url
      }
    end
    
    alias_method :web_json, :pretty_json

  end


  class ItemBasket < Item

    def url
      "#{$mobile_host}/baskets/#{id}"
    end
      
    def init_data
      ::Basket.find_by_id(id)
    end

    def pretty_json
      super.merge(total_return: data.try(:total_return))
    end
    
    def web_json
      pretty_json.merge(title: title, url: web_url)
    end
    
    def title
      "评论了组合 <a href=\"#{web_url}\" target=\"_blank\">#{name}</a>"
    end
    
    def web_url
      "/baskets/#{id}"
    end

  end




  class ItemArticle < Item

    def init_data
      ::Article.find_by_id(id)
    end

    def pretty_json
      super.merge({category: category})
    end

    def url
      "#{$mobile_host}/pages/articles/#{id}"
    end
    
    def web_json
      pretty_json.merge(title: title, url: web_url)
    end
    
    def title
      "评论了专栏 <a href=\"#{web_url}\" target=\"_blank\">#{name}</a>"
    end
    
    def web_url
      "/articles/#{id}"
    end

  end


  class ItemFriend < Item
    
    def init_data
      MD::User.where(id: id).first
    end

    def pretty_json
      {
        id: _id.to_s,
        name: name,
      }
    end

  end


  class ItemStock < Item
    
    def init_data
      ::Rs::Stock.find(id)
    end

    def pretty_json
      {
        id: _id.to_s,
        type: type,
        name: name,
        symbol: ext_data.try(:with_indifferent_access).try(:[], :symbol),
        realtime_price: data.try(:realtime_price),
        change_percent: data.try(:change_percent),
        # listed_state: data.try(:listed_state),
        followed: ext_data.to_h[:followed] || false  # followed 外部实时塞入
      }
    end

    def web_json
      pretty_json.merge(title: title, url: web_url)
    end
    
    def title
      "评论了股票 <a class=\"j_bop\" data-sid=\"#{id}\" href=\"#{web_url}\" target=\"_blank\">$#{name}$</a>"
    end
    
    def web_url
      "/stocks/#{id}"
    end

  end

  class ItemTopic < Item
    
    def init_data
      ::Topic.find_by_id(id)
    end

    def url
      "#{$mobile_host}/pages/topics/#{id}"
    end

    def pretty_json
      super.merge({tags: tags, category: category})
    end
    
    def web_json
      pretty_json.merge(title: title, url: web_url)
    end
    
    def title
      "评论了热点 <a href=\"#{web_url}\" target=\"_blank\">#{name}</a>"
    end
    
    def web_url
      "/topics/#{id}"
    end

  end
  
  class ItemNews < Item
    
    def init_data
      MD::Data::SpiderNews.where(id: id).first
    end

    def url
      "#{$mobile_host}/pages/news/#{id}"
    end
    
    def pretty_json
      super.merge(ext_data.to_h)
    end
    
    def web_json
      pretty_json.merge(title: title, url: web_url)
    end
    
    def title
      "评论了新闻 <a href=\"#{web_url}\" target=\"_blank\">#{name}</a>"
    end
    
    def web_url
      "/news/#{id}"
    end
    
  end

  class ItemTradingAccount < Item
    
    def init_data
      ::TradingAccount.find_by_id(id)
    end

  end

  class ItemPlate < Item

    def stock
      ::Rs::Stock.find(ext_data.with_indifferent_access[:stock_id])
    end
    
    def pretty_json
      {
        realtime_price: stock.try(:realtime_price),
        stock_change_percent: stock.try(:change_percent),
        url: plate_url
      }.merge!(ext_data)
    end

    def plate_url
      plate_stock_id.blank? ? "" : "#{$mobile_host}/plates/#{plate_stock_id}"
    end

    def plate_stock_id
      ext_data[:plate_stock_id]
    end
  end
  
  class ItemComment < Item
    def init_data
      ::Comment.find_by_id(id)
    end
    
    def pretty_json
      {id: id, type: "comment" }.merge!(deleted? ? ext_data.to_h.merge!(message: "该评论已被删除!") : ext_data.to_h)
    end

    def web_json
      if deleted?
        {message: ''}
      else
        {id: id, type: type}.merge! ext_data.to_h
      end
    end

    def deleted?
      ext_data["deleted"]
    end
  end
  
  class ItemBasketAdjustLog < Item
    def init_data
      ::BasketAdjustLog.find_by_id(id)
    end
    
    def web_json
      ext_data
    end

    def pretty_json
      super.merge ext_data.to_h
    end
  end
  
  class ItemContest < Item
    def init_data
      ::Contest.find_by_id(id)
    end
    
    def web_json
      pretty_json.merge(title: title, url: web_url)
    end
    
    # todo: 不同大赛的url可能需要动态获取
    def title
      "评论了大赛 <a href=\"#{web_url}\" target=\"_blank\">#{name}</a>"
    end
    
    def web_url
      "/events/shipan"
    end
  end

end
