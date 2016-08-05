require File.expand_path('../boot', __FILE__)

require 'active_record/railtie'
require 'action_controller/railtie'
require 'action_mailer/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Caishuo
  class Application < Rails::Application
    # 删除多余的中间件
    config.middleware.delete 'Rack::Runtime'
    # config.middleware.delete 'ActionDispatch::RequestId'
    config.middleware.delete 'ActionDispatch::RemoteIp'
    # config.middleware.delete 'ActionDispatch::Head' #Etag
    config.middleware.delete 'ActionDispatch::BestStandardsSupport'

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    #config.eager_load_paths += %W(#{config.root}/lib)
    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Beijing'
    config.active_record.default_timezone = :local

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]
    I18n.enforce_available_locales = false
    config.i18n.default_locale = "zh-CN"
    I18n.locale = "zh-CN"
    #config.i18n.fallbacks = true

    # Configure the default encoding used in tempates for ruby 1.9
    config.encoding = 'utf-8'

    # Enable the asset pipeline
    config.assets.enabled = true
    #config.assets.paths << "#{Rails}/vendor/assets/fonts"
    config.assets.precompile += %w(application.js base.js jquery.js jquery_ujs.js portfolio.js admin.js setting.js home.js 
    passwords.js sessions.js highstock.js baskets.js baskets_add.js basket_show.js baskets_base.js stock_search.js article.js
    basket_info.js users.js orders.js stocks.js landings.js profiles.js account/passwords.js account/registrations.js account/users.js baskets_custom.js
    home.css admin.css justified-nav.css pure-min.css yui-home.css users.css jquery jquery.Jcrop.css bootstrap.css autocomplete.css jquery-ui.css
    publisher-client.js users/orders.js accounting.min.js user/baskets.js mobile/shares/wechat_share.js mobile/shares/stocks.js translate.js basket_index.js users/stocks.js 
    admin/topics.js topics/show.js stock_market_index.js bubble.js account/profiles.js stocks_index.js stock.js user/positions.js accounts/overview.js
    accounts/positions.js user/orders.js mobile.js events.js events/shipan.js market/zxg/topics.js jquery.timeago.js jquery.timeago.settings.js admin/articles.js 
    events/guess_stocks.js
    )

    # 使用redis作为默认缓存
    #require File.expand_path("../../app/models/setting", __FILE__)
    redis_conf = YAML.load_file(Rails.root.join('config', 'redis.yml'))[Rails.env]
    config.cache_store = :redis_store, "redis://#{redis_conf['host']}:#{redis_conf['port']}"
    
    # 替换默认解析器 jbuilder activesupport底层都使用multi_json
    MultiJson.use :yajl 
       
    # after_commit出错提示
    config.active_record.raise_in_transactional_callbacks = true

    config.action_controller.page_cache_directory = "#{Rails.root.to_s}/public/caches"
  end
end
