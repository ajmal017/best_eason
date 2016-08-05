require "elasticsearch_ext/persistence/repository/search"

require "elasticsearch_ext/persistence/repository/response"
require "elasticsearch_ext/persistence/repository/response/base"
require "elasticsearch_ext/persistence/repository/response/result"
require "elasticsearch_ext/persistence/repository/response/results"
require "elasticsearch_ext/persistence/repository/response/records"
require "elasticsearch_ext/persistence/repository/response/pagination"

if defined?(::WillPaginate)
   Elasticsearch::Persistence::Repository::Response::Response.__send__ :include,  Elasticsearch::Persistence::Repository::Response::Pagination::WillPaginate
end