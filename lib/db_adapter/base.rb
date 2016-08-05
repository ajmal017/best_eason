require 'forwardable'
require "db_adapter/active_record"
require "db_adapter/mongodb"
require "db_adapter/elasticsearch"

class DbAdapter::Base
  extend Forwardable
  attr_reader :klass, :db_source

  def_delegators :db_source, :find, :find_by, :where

  def initialize(klass)
    @klass = klass
  end

  def db_source
    @db_source ||= begin
      klass_name = klass.name
      if klass_name.start_with? "MD::"
        DbAdapter::Mongodb
      elsif klass_name.start_with? "ES::"
        DbAdapter::Elasticsearch
      else
        DbAdapter::ActiveRecord
      end
    end.new klass
  end

end
