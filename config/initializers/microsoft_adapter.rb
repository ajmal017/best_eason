# seo sitemap upload 适配微软云
module SitemapGenerator
  class MicrosoftAdapter
    attr_accessor :uploader

    def initialize(name, path="sitemap/")
      @uploader = SitemapUploader.new(name, path)
    end

    # 上传
    def write(location, raw_data)
      SitemapGenerator::FileAdapter.new.write(location, raw_data)

      # 上传微软云
      uploader.store!(File.open(location.path)) if Rails.env.production?
    end
  end
end
