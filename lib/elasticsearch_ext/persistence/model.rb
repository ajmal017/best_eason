require "elasticsearch_ext/persistence/model/store"
require "elasticsearch_ext/persistence/model/find"

module ElasticsearchExt
    module Model
      extend ActiveSupport::Concern

      module ClassMethods
        def client
          gateway.client
        end

        def per_page
          20
        end

      end

      def created_at
        @created_at.try(:in_time_zone)
      end

      def updated_at
        @updated_at.try(:in_time_zone)
      end

      def to_hash
        super.merge({created_at: @created_at.utc, updated_at: @updated_at.utc})
      end

  end
end
