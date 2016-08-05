class MobileRecommend < Recommend

  TYPE = [
    ["图片", "IMG"],
    ["html5", "H5"],
    ["组合", "BASKET"],
    ["组合列表", "BASKET_FILTER"],
    ["理财产品", "P2P_PRODUCT"],
  ]

  class << self

    def banners_key
      "#{@@redis_key}:mobile:banners"
    end

    def banners_sort_key
      "#{@@redis_key}:mobile:banners_sort"
    end

    def add_banner(banner_upload_id, title, type, url)
      infos = {title: title, type: type, url: url}
      $redis.hset(banners_key, banner_upload_id, Marshal.dump(infos))
    end

    def banner_url_and_images
      banners_info = self.banners
      banner_image_urls = Upload::Recommend.where(id: banners_info.keys).map{|b| [b.id.to_s, b.image.url]}.to_h
      upload_ids = self.banners_upload_ids(banners_info.keys)
      upload_ids.map do |upload_id|
        infos = banners_info[upload_id]
        [upload_id, Marshal.load(infos).merge({image_url: banner_image_urls[upload_id]})]
      end
    end

    # ios端设置是否要显示广告
    def set_ad(is_open, version = nil, url = nil, pic = nil)
      $redis.hmset(ad_key, "is_open", is_open, "version", version, "url", url, "pic", pic)
    end

    def ad_version
      $redis.hget(ad_key, "version")
    end

    def ad_is_open?
      $redis.hget(ad_key, "is_open").to_i == 1
    end

    def ad_url
      $redis.hget(ad_key, "url")
    end

    def ad_pic
      $redis.hget(ad_key, "pic")
    end

    def ad_infos(client_version)
      client, version = client_version.to_s.split("-")
      status = (client == "iOS" && version == ad_version && ad_is_open?)
      infos = {status: status ? 1 : 0}
      infos.merge!({url: ad_url, pic: ad_pic}) if status
      infos
    end

    def ad_key
      "cs:mobile:ad_setting"
    end
  end
end

