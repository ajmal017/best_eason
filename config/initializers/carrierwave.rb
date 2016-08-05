require 'azure'

CarrierWave.configure do |config|
  config.azure_storage_account_name = Setting.azure.account_name
  config.azure_storage_access_key = Setting.azure.access_key
  config.azure_storage_blob_host = Setting.azure.blob_host # optional
  config.azure_container = 'static'
  config.asset_host = 'https://cdn.caishuo.com' if Rails.env.production? # optional
end

Azure.configure do |config|
  config.storage_account_name = Setting.azure.account_name
  config.storage_access_key   = Setting.azure.access_key
  config.storage_blob_host    = Setting.azure.blob_host 
end


# CarrierWave.configure do |config|
#   config.azure_credentials = {
#     storage_account_name: Azure.config.storage_account_name,
#     storage_access_key: Azure.config.storage_access_key,
#     storage_blob_host: Azure.config.storage_blob_host
#   }
#   config.azure_container = 'static'
#   # config.azure_host = 'https://cdn9-caishuo-com.alikunlun.com'
#   config.azure_host = "https://cdn.caishuo.com"
#   # config.azure_host = "https://dn-caishuo.qbox.me"
# end


#设置图像质量
module CarrierWave
  module MiniMagick
    def quality(percentage)
      manipulate! do |img|
        img.quality(percentage.to_s)
        img = yield(img) if block_given?
        img
      end
    end
  end
end

$azure = Azure::Blob::BlobService.new
