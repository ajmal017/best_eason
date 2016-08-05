module Elasticsearch
  module Persistence
    module Repository
      module Response

        # Encapsulates the collection of documents returned from Elasticsearch
        #
        # Implements Enumerable and forwards its methods to the {#results} object.
        #
        class Results
          include Base
          include Enumerable

          delegate :each, :empty?, :size, :slice, :[], :to_a, :to_ary, to: :results

          # @see Base#initialize
          #
          def initialize(klass, response, options={})
            super
            @response   = Hashie::Mash.new(response.response)
          end

          # Returns the {Results} collection
          #
          def results
            @results  = response['hits']['hits'].map { |hit| klass.gateway.deserialize(hit.to_hash) }
          end

        end
      end
    end
  end
end
