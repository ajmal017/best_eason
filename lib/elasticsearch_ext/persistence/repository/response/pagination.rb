require 'active_support/concern'
require 'will_paginate/collection'

module Elasticsearch
  module Persistence
    module Repository
       module Response
        module Pagination

          module WillPaginate
            extend ActiveSupport::Concern

            include ::WillPaginate::CollectionMethods

            included do
              methods = [:current_page, :offset, :length, :per_page, :total_entries, :total_pages, :previous_page, :next_page, :out_of_bounds?]
              Elasticsearch::Persistence::Repository::Response::Results.__send__ :delegate, *methods, to: :response
              Elasticsearch::Persistence::Repository::Response::Results.__send__ :include, ::WillPaginate::CollectionMethods
            end

            def offset
              (current_page - 1) * per_page
            end

            def length
              search.definition[:size]
            end

            # Main pagination method
            #
            # @example
            #
            #     Article.search('foo').paginate(page: 1, per_page: 30)
            #
            def paginate(options)
              page = [options[:page].to_i, 1].max
              per_page = (options[:per_page] || klass.per_page).to_i

              search.definition.update size: per_page,
                                       from: (page - 1) * per_page
              self
            end

            # Return the current page
            #
            def current_page
              search.definition[:from] / per_page + 1 if search.definition[:from] && per_page
            end

            # Pagination method
            #
            # @example
            #
            #     Article.search('foo').page(2)
            #
            def page(num)
              paginate(page: num, per_page: per_page) # shorthand
            end

            # Return or set the "size" value
            #
            # @example
            #
            #     Article.search('foo').per_page(15).page(2)
            #
            def per_page(num = nil)
              if num.nil?
                search.definition[:size]
              else
                paginate(page: current_page, per_page: num) # shorthand
              end
            end

            # Returns the total number of results
            #
            def total_entries
              results.total
            end



          end # WillPaginate
        end # Pagination

      end 

    end 
  end
end
