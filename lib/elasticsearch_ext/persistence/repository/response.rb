require 'elasticsearch/model/response'
module Elasticsearch
  module Persistence
    module Repository

      # Contains modules and classes for wrapping the response from Elasticsearch
      #
      module Response

        # Encapsulate the response returned from the Elasticsearch client
        #
        # Implements Enumerable and forwards its methods to the {#results} object.
        #
        class Response < Elasticsearch::Model::Response::Response
         

          # Returns the collection of "hits" from Elasticsearch
          #
          # @return [Results]
          #
          def results
            @results ||= Results.new(klass, self)
          end

          # Returns the collection of records from the database
          #
          # @return [Records]
          #
          def records
            @records ||= Records.new(klass, self)
          end

          # Returns the "took" time
          #
          def took
            response.response['took']
          end

          # Returns whether the response timed out
          #
          def timed_out
            response.response['timed_out']
          end

          # Returns the statistics on shards
          #
          def shards
            Hashie::Mash.new(@response.response['_shards'])
          end
        end
      end
    end
  end
end
