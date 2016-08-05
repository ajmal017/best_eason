module CarrierWave::Uploader::Configuration
  module ClassMethods

    def storage_with_azure(storage = nil)
      storage = :azure if Rails.env.production?
      storage_without_azure(storage)
    end

    alias_method_chain :storage, :azure
  end
end

module CarrierWave
  module Storage
    class Azure < Abstract
      class File
        def store!(file)
          @content = file.read
          @content_type = file.content_type
          @connection.create_block_blob @uploader.azure_container, @path, @content, content_type: @content_type, cache_control: "public, max-age=31536000"
          true
        end
      end
    end
  end
end

