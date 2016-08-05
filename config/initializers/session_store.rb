# Be sure to restart your server when you modify this file.

#if Rails.env.development?
  Caishuo::Application.config.session_store :cookie_store, key: Setting.session_key, domain: Setting.domain
#elsif Rails.env.staging?
#  Caishuo::Application.config.session_store :cookie_store, key: '_caishuo_store', domain: '.office.caishuo.com'
#else
#  Caishuo::Application.config.session_store :cookie_store, key: '_caishuo_store', domain: '.caishuo.com'
#end
