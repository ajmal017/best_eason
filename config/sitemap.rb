# Set the host name for URL creation
SitemapGenerator::Sitemap.default_host = "http://www.caishuo.com"
SitemapGenerator::Sitemap.adapter = SitemapGenerator::MicrosoftAdapter.new("sitemap.xml.gz")

SitemapGenerator::Sitemap.create do
  # Put links creation logic here.
  #
  # The root path '/' and sitemap index file are added automatically for you.
  # Links are added to the Sitemap in the order they are specified.
  #
  # Usage: add(path, options={})
  #        (default options are used if you don't specify)
  #
  # Defaults: :priority => 0.5, :changefreq => 'weekly',
  #           :lastmod => Time.now, :host => default_host
  #
  # Examples:
  #
  # Add '/articles'
  #
  #   add articles_path, :priority => 0.7, :changefreq => 'daily'
  #
  # Add all articles:
  #
  #   Article.find_each do |article|
  #     add article_path(article), :lastmod => article.updated_at
  #   end

  %w{/articles /topics /stocks /baskets}.each do |url|
    add url, :priority => 0.7, :changefreq => 'daily'
  end

  Category.all.each do |category|
    add "categories/#{category.id}/articles", :priority => 0.7, :changefreq => 'daily'
  end

  Article.select(:id, :updated_at).each do |article|
    add "articles/#{article.id}", priority: 0.7, changefreq: 'weekly', lastmod: article.updated_at
  end



end

