require 'ostruct'

namespace :sitemap do

  desc "update sitemap adapter"
  task :refresh_adapter => :environment do
    %w[sitemap_adapter_pattern sitemap_adapter_url open_search].each do |f_name|
      td = {path: "#{Rails.root}/public/sitemap/#{f_name}.xml.gz", directory: "#{Rails.root}/public/sitemap/"}
      SitemapGenerator::MicrosoftAdapter.new("#{f_name}.xml.gz").write(OpenStruct.new(td), File.open("config/#{f_name}.xml").read)
    end
  end
end
