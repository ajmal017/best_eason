class MobileP2pRecommend < MobileRecommend
  TYPE = [
    ["图片", "IMG"],
    ["html5", "H5"],
    ["组合", "BASKET"],
    ["组合列表", "BASKET_FILTER"],
  ]

  class << self

    def banners_key
      "#{@@redis_key}:mobile:p2p:banners"
    end

    def banners_sort_key
      "#{@@redis_key}:mobile:p2p:banners_sort"
    end

    def ad_key
      "cs:mobile:p2p:ad_setting"
    end

  end

end
