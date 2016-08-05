# es search module
module Searchable
  extend ActiveSupport::Concern

  included do |klass|
    include Elasticsearch::Model
    index_name klass.table_name
    document_type 'doc'

    # TODO： 异步
    after_commit on: [:create] do
      __elasticsearch__.index_document if can_index_to_es?
    end

    after_commit on: [:update] do
      __elasticsearch__.update_document if can_index_to_es?
    end

    after_commit on: [:destroy] do
      __elasticsearch__.delete_document if can_index_to_es?
    end
  end

  def can_index_to_es?
    true
  end

  class_methods do
    def inherited(inherit_klass)
      super(inherit_klass)
      inherit_klass.class_eval do
        index_name inherit_klass.table_name
        document_type 'doc'
      end
    end
  end
end
