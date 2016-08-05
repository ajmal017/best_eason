module Elasticsearch
  module Persistence
    module Repository

      # Returns a collection of domain objects by an Elasticsearch query
      #
      module Search



        class SearchRequest
          attr_reader :klass, :definition, :options

          # @param klass [Class] The class of the model
          # @param query_or_payload [String,Hash,Object] The search request definition
          #                                              (string, JSON, Hash, or object responding to `to_hash`)
          # @param options [Hash] Optional parameters to be passed to the Elasticsearch client
          #
          def initialize(klass, query_or_payload, options={})
            @klass   = klass
            @options = options

            __index_name    = options[:index] || klass.index_name
            __document_type = options[:type]  || klass.document_type

            case
              # search query: ...
              when query_or_payload.respond_to?(:to_hash)
                body = query_or_payload.to_hash

              # search '{ "query" : ... }'
              when query_or_payload.is_a?(String) && query_or_payload =~ /^\s*{/
                body = query_or_payload

              # search '...'
              else
                q = query_or_payload
            end

            if body
              @definition = { index: __index_name, type: __document_type, body: body }.update options
            else
              @definition = { index: __index_name, type: __document_type, q: q }.update options
            end
          end

          # Performs the request and returns the response from client
          #
          # @return [Hash] The response from Elasticsearch
          #
          def execute!
            klass.client.search(@definition)
          end
        end

        # Returns a collection of domain objects by an Elasticsearch query
        #
        # Pass the query either as a string or a Hash-like object
        #
        # @example Return objects matching a simple query
        #
        #     repository.search('fox or dog')
        #
        # @example Return objects matching a query in the Elasticsearch DSL
        #
        #    repository.search(query: { match: { title: 'fox dog' } })
        #
        # @example Define additional search parameters, such as highlighted excerpts
        #
        #    results = repository.search(query: { match: { title: 'fox dog' } }, highlight: { fields: { title: {} } })
        #     results.map_with_hit { |d,h| h.highlight.title.join }
        #     # => ["quick brown <em>fox</em>", "fast white <em>dog</em>"]
        #
        # @example Perform aggregations as part of the request
        #
        #     results = repository.search query: { match: { title: 'fox dog' } },
        #                                 aggregations: { titles: { terms: { field: 'title' } } }
        #     results.response.aggregations.titles.buckets.map { |term| "#{term['key']}: #{term['doc_count']}" }
        #     # => ["brown: 1", "dog: 1", ... ]
        #
        # @example Pass additional options to the search request, such as `size`
        #
        #     repository.search query: { match: { title: 'fox dog' } }, size: 25
        #     # GET http://localhost:9200/notes/note/_search
        #     # > {"query":{"match":{"title":"fox dog"}},"size":25}
        #
        # @return [Elasticsearch::Persistence::Repository::Response::Results]
        #
        def search(query_or_definition, options={})
          search   = SearchRequest.new(klass, query_or_definition, options)
          Response::Response.new(klass, search)
        end

        # Return the number of domain object in the index
        #
        # @example Return the number of all domain objects
        #
        #     repository.count
        #     # => 2
        #
        # @example Return the count of domain object matching a simple query
        #
        #     repository.count('fox or dog')
        #     # => 1
        #
        # @example Return the count of domain object matching a query in the Elasticsearch DSL
        #
        #    repository.search(query: { match: { title: 'fox dog' } })
        #    # => 1
        #
        # @return [Integer]
        #
        def count(query_or_definition=nil, options={})
          query_or_definition ||= { query: { match_all: {} } }
          response = search query_or_definition, options.update(search_type: 'count')
          response.response.hits.total
        end
      end

    end
  end
end
