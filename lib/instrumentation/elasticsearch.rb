require 'elasticsearch/rails/instrumentation/publishers'
require 'elasticsearch/rails/instrumentation/log_subscriber'
require 'elasticsearch/rails/instrumentation/controller_runtime'

module Elasticsearch
  module Rails
    module Instrumentation

      module ControllerRuntime
        extend ActiveSupport::Concern

        protected

        module ClassMethods
          def log_process_action(payload)
            messages, elasticsearch_runtime = super, payload[:elasticsearch_runtime]
            if elasticsearch_runtime
              runtime = elasticsearch_runtime.to_f
              color = if runtime < 10
                        "\e[32m"
                      elsif runtime < 50
                        "\e[33m"
                      else
                        "\e[31m"
                      end
              messages << ("Elasticsearch: \e[1m#{color}%.1f\e[0m ms" % runtime)
            end
            messages
          end
        end
      end
    end
  end
end

Elasticsearch::Persistence::Repository::Search::SearchRequest.class_eval do
  include Elasticsearch::Rails::Instrumentation::Publishers::SearchRequest
end
Elasticsearch::Model::Searching::SearchRequest.class_eval do
  include Elasticsearch::Rails::Instrumentation::Publishers::SearchRequest
end if defined?(Elasticsearch::Model::Searching::SearchRequest)

ActiveSupport.on_load(:action_controller) do
  include Elasticsearch::Rails::Instrumentation::ControllerRuntime
end