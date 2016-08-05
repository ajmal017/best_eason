class Recommend
  @@redis_key = "recommends"

  class << self
    def basket
      basket_id = $redis.get(basket_key)
      Basket.finished.find_by_id(basket_id)
    end

    def set_basket(basket_id)
      if Basket.find_by_id(basket_id).present?
        $redis.set(basket_key, basket_id)
      else
        false
      end
    end

    def basket_key
      "#{@@redis_key}:home:basket"
    end

    def topic
      topic_id = $redis.get(topic_key)
      Topic.find_by_id(topic_id)
    end

    def set_topic(topic_id)
      if Topic.find_by_id(topic_id).present?
        $redis.set(topic_key, topic_id)
      else
        false
      end
    end

    def topic_key
      "#{@@redis_key}:home:topic"
    end

    def stock_search
      $redis.hgetall(stock_search_key)
    end

    def set_stock_search(options)
      title = options[:title]
      url = options[:url]
      desc = options[:desc]
      count = options[:count]
      if title.present? && url.present? && desc.present? && count.present?
        $redis.hmset(stock_search_key, "title", title, "url", url, "desc", desc, "count", count)
      else
        false
      end
    end

    def stock_search_key
      "#{@@redis_key}:home:stock_search"
    end

    def banner_url_and_images
      banners_info = self.banners
      banner_image_urls = Upload::Recommend.where(id: banners_info.keys).map{|b| [b.id.to_s, b.image.url(:large)]}.to_h
      upload_ids = self.banners_upload_ids(banners_info.keys)
      upload_ids.map do |upload_id|
        infos = banners_info[upload_id]
        [upload_id, Marshal.load(infos).merge({image_url: banner_image_urls[upload_id]})]
      end
    end

    def banners
      $redis.hgetall(banners_key)
    end

    def add_banner(banner_upload_id, title, url)
      infos = {title: title, url: url}
      $redis.hset(banners_key, banner_upload_id, Marshal.dump(infos))
    end

    def delete_banner(banner_upload_id)
      $redis.hdel(banners_key, banner_upload_id)
    end

    def banners_key
      "#{@@redis_key}:home:banners"
    end

    def banners_upload_ids(stored_upload_ids)
      sorted_upload_ids = $redis.get(banners_sort_key).to_s.split(",")
      processed_upload_ids = (stored_upload_ids.sort.reverse - sorted_upload_ids) + sorted_upload_ids
      processed_upload_ids & stored_upload_ids
    end

    def set_banners_sort(upload_ids)
      $redis.set(banners_sort_key, upload_ids.uniq.join(","))
    end

    def banners_sort_key
      "#{@@redis_key}:home:banners_sort"
    end

    def add_user(user_id, desc = "")
      del_user(user_id)
      $redis.hset(users_key, user_id, desc)
      add_to_users_position(user_id)
    end

    def del_user(user_id)
      $redis.hdel(users_key, user_id)
    end

    def user_infos
      users_desc = $redis.hgetall(users_key)
      users = User.where(id: users_desc.keys).map{|u| [u.id.to_s, u]}.to_h
      users_position.map{|uid| [users[uid], users_desc[uid]]}.select{|x| x[0].present? }
    end

    def users_key
      "#{@@redis_key}:home:users"
    end

    def users_position
      $redis.get(users_position_key).to_s.split(",")
    end

    def set_users_position(ids)
      $redis.set(users_position_key, ids.uniq.join(","))
    end

    def add_to_users_position(uid)
      $redis.set(users_position_key, users_position.push(uid.to_s).uniq.join(","))
    end

    def users_position_key
      "#{@@redis_key}:home:users_position"
    end
  end
end
