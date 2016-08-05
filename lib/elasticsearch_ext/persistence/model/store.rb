module Elasticsearch
  module Persistence
    module Model

      # This module contains the storage related features of {Elasticsearch::Persistence::Model}
      #
      module Store
        module ClassMethods #:nodoc:

          # Creates a class instance, saves it, if validations pass, and returns it
          #
          # @example Create a new person
          #
          #     Person.create name: 'John Smith'
          #     # => #<Person:0x007f889e302b30 ... @id="bG7yQDAXRhCi3ZfVcx6oAA", @name="John Smith" ...>
          #
          # @return [Object] The model instance
          #
          def delete_all(query_or_definition=nil, options={})
            type = document_type || (klass ? __get_type_from_class(klass) : nil)
            case
            when query_or_definition.nil?
              response = gateway.client.delete_by_query( { index: index_name, type: type, q: "*" }.merge(options) )
            when query_or_definition.respond_to?(:to_hash)
              response = gateway.client.delete_by_query( { index: index_name, type: type, body: query_or_definition.to_hash }.merge(options) )
            when query_or_definition.is_a?(String)
              response = gateway.client.delete_by_query( { index: index_name, type: type, q: query_or_definition }.merge(options) )
            else
              raise ArgumentError, "[!] Pass the delete definition as a Hash-like object or pass the query as a String" +
                                   " -- #{query_or_definition.class} given."
            end
          end


        end

      end

    end
  end
end
