# source 'https://rubygems.org'
source 'https://ruby.taobao.org'

gem 'rails', '4.2.4'
gem 'rake', '10.3.0'

# 数据库
gem 'mysql2', '~> 0.3.18'
gem 'hiredis'
gem 'sqlite3'
# gem 'mongo', '~> 2.1'
gem 'moped'
gem 'mongoid', '5.0.1'
gem 'bson', '3.2.6'
gem 'sitemap_generator'
gem 'mongoid_orderable'

# 资源模板引擎
gem 'sass-rails', '~> 4.0.2'
gem 'coffee-rails', '~> 4.0.0'
gem 'uglifier', '>= 1.3.0'

gem "non-stupid-digest-assets"

# Js组件
gem 'jquery-rails', '~> 3.0.4'

# 富文本编辑器
gem 'rails_kindeditor', '0.4.5'
gem 'sanitize', '2.0.6'

# Tag
gem 'acts-as-taggable-on', '~> 3.1.0'

# 权限验证
gem 'cancancan', '1.7.1'

# 表单和客户端验证
gem 'simple_form'
gem 'ransack', '~> 1.5.0' # search

# 异步和定时任务
gem 'resque', '~> 1.25.1', require: 'resque/server'
gem 'resque-scheduler', '3.0.0'
gem 'resque-dynamic-queues'
gem 'resque-retry'
gem 'eventmachine'
gem 'rufus-scheduler', '2.0.24'

# rabbitmq消息队列ruby client
gem 'amqp'
gem 'sneakers', '~> 0.1.1.pre'

# 缓存系统
gem 'redis-objects'
gem 'redis-namespace'
gem 'redis-rails'
gem 'redis-activesupport'

# Http client
gem 'faraday'
gem 'typhoeus'

# 分页
gem 'will_paginate', '3.0.4'
gem 'will_paginate_mongoid'

# Yaml 配置信息
gem 'settingslogic', '~> 2.0.9'

# Rails variables in your JS
gem 'gon'

# Hash ID, 用来生成加密ID，来保护数据库id, 需保证可逆加密
gem 'hashids'

# 解析器
gem 'jbuilder', '~> 2.0.2'
gem 'yajl-ruby', '~> 1.2.0'
gem 'nokogiri'
gem 'xml-simple', '~> 1.1.4'
gem 'oj'

gem 'hashie'

# 用户系统
gem 'devise', '3.4.1'

# 文件和图片处理
gem 'carrierwave', '0.10.0'
gem 'mini_magick', '3.7.0'
gem 'carrierwave-azure', '0.0.3'
gem 'carrierwave-mongoid'

# 汉字转拼音
gem 'chinese_pinyin', '~> 0.4.2'
# 利用 MediaWiki 作中文简繁互转
gem 'zhconv'

# 股票
gem 'yahoofinance', '~> 1.2.2'

# 批量导入
gem 'activerecord-import', '0.7.0'

# mongoid enum支持 mongoid 5.0+
gem 'mongoid-enum', git: "ssh://git@gitlab.caishuo.com:10022/ruby/mongoid-enum.git", tag: "v1.0.0"

# 为table或column添加comment
gem 'migration_comments', '~> 0.3.2'

# xls、csv导入
gem 'roo', '1.13.2'

# 网页数据抓取与解析
gem "mechanize"

# 状态机
gem 'aasm', '3.3.1'

gem 'coderay'

gem 'elasticsearch-rails'
gem 'elasticsearch-persistence', require: 'elasticsearch/persistence/model'
gem 'descendants_tracker' # ES Rails 4.2升级之后报错 cannot load such file -- descendants_tracker

group :production do
  # gem 'unicorn', '4.8.3'
  # gem 'unicorn-worker-killer'
  gem 'bluepill'
  gem 'gctools'
  gem 'puma'
end

# 异常通知
gem 'exception_notification', '~> 4.0.1'

gem 'mail', '~> 2.6.3'

# for App API
gem "grape", "0.11.0"
gem "grape-entity", '0.4.5'
gem "grape-swagger", '0.10.1'
gem "rack-cors", "0.3.1", require: "rack/cors"

# 手机端推送
gem 'jpush', git: 'git://github.com/jpush/jpush-api-ruby-client.git'

# 方差计算
gem 'descriptive_statistics'

gem 'turbolinks'
# 图片验证码
gem 'easy_captcha'

# 生成excel
gem 'ekuseru'

# 开发环境
group :development, :test do
  gem 'capistrano', '3.2.1'
  gem 'capistrano-bundler', '~> 1.1.2'
  gem 'capistrano-rails', '~> 1.1.1'
  gem 'annotate', '~> 2.6.5'
  gem 'commands', '~> 0.2.1'
  gem 'foreman', '~> 0.74.0'
  gem 'capistrano3-puma'
  gem 'rubocop', require: false
end

group :development do
  gem 'guard-rspec', '~> 3.0.2'
  gem 'guard-spork', '~> 1.5.1'
  gem 'spork-rails', github: 'sporkrb/spork-rails'
  gem 'rb-fsevent', '~> 0.9.3'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'pry', "~> 0.9.12"
  gem 'pry-nav', "~> 0.2.3"
  gem "bullet", "~> 4.14" # 检查N+1查询
  gem 'awesome_print'
end
gem "ruby-prof"

group :development, :staging do
  gem 'meta_request'
end

group :development, :production, :staging do
  gem 'newrelic_rpm'
  gem 'newrelic-redis'
  gem 'newrelic_mongodb'
  # gem 'newrelic_moped'
  gem 'newrelic-grape'
end

# group :testing do
#   gem 'oneapm_rpm'
# end

# source 'http://rubygems.oneapm.com' do
#   gem 'oneapm_rpm'
# end

group :development, :test do
  gem "rspec-rails", "~> 2.14.0"
  gem "factory_girl_rails", "~> 4.2.1"
end

group :test do
  gem "faker", "~> 1.1.2"
  gem "capybara", "~> 2.1.0"
  gem "database_cleaner", "~> 1.0.1"
  gem "launchy", "~> 2.3.0"
  gem "shoulda-matchers", "~> 2.2.0"
  gem "selenium-webdriver", "~> 2.35.1"
  gem 'simplecov', require: false
  gem 'cucumber-rails', require: false
  gem 'test-unit'
  gem 'grape-entity-matchers'
end

# for upgrade
group :development do
  gem 'web-console', '~> 2.0'
  gem 'brakeman', require: false
end

gem 'responders', '~> 2.0'
gem "fast_trie"

gem 'rest_client', git: 'ssh://git@gitlab.caishuo.com:10022/ruby/rest_client.git', tag: "1.2.5"
gem "exchange", git: "ssh://git@gitlab.caishuo.com:10022/ruby/exchange.git", tag: "0.3.9"
gem 'grape-rails-cache'
gem "publisher", git: "ssh://git@gitlab.caishuo.com:10022/ruby/publisher.git", tag: '0.0.8'
gem "request_pool", git: "ssh://git@gitlab.caishuo.com:10022/ruby/request_pool.git", tag: '0.0.20'
gem "p2p_client", git: "ssh://git@gitlab.caishuo.com:10022/ruby/p2p_client.git", tag: '0.0.66'
# gem "request_pool", path: '/Users/warrenoo/Dropbox/workspace/request_pool'
# gem "p2p_client", path: '/Users/marcusma/projects/caishuo/p2p_client'
# gem "p2p_client", path: '/Users/warrenoo/Dropbox/workspace/p2p_client'

gem 'omniauth-qq-oauth2', git: "https://github.com/Warrenoo/omniauth-qq-oauth2.git"
gem 'omniauth-wechat-oauth2', git: "https://github.com/Warrenoo/omniauth-wechat-oauth2.git", tag: "0.1.1"
gem 'omniauth-weibo-oauth2'
gem 'actionpack-page_caching'
