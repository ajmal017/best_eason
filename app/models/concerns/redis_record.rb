module RedisRecord
  extend ActiveSupport::Concern

  ALLOW_COUNT = 5
  INTERVAL_KEY = "|&&|"
  
  included do
    attr_accessor :id
    cattr_accessor :attrs, :presence
  end

  def initialize(opts={})
    self.class.attrs.each do |attr|
      instance_variable_set("@#{attr}", opts.fetch(attr))
    end
  end

  def save
    $redis.zremrangebyscore(self.class.redis_key, id, id)
    $redis.zadd(self.class.redis_key, id, self.class.attrs.map{|attr|self.send(attr)}.join(INTERVAL_KEY)) if self.class.presence.nil? || self.send(self.class.presence).present?
  end

  module ClassMethods

    def has_attributes(*attrs, presence: nil)
      self.attrs = attrs.map(&:to_sym)
      self.presence = presence
      self.send(:attr_accessor, *self.attrs)
      self.instance_eval do |r|
        define_method :initialize do |opts={}|
          (self.attrs + [:id]).each do |attr|
            instance_variable_set("@#{attr.to_s}", opts.fetch(attr))
          end if opts.present?
        end
      end
    end

    def all
      results = $redis.zrange(redis_key, 0, -1, with_scores: true)

      Array(1..ALLOW_COUNT).map do |i|
        if result = results.find{|p| p.last.to_i == i}

          arr  = result.first.split(INTERVAL_KEY)
          opts = {id: result.last.to_i}

          self.attrs.each_with_index do |attr, i|
            opts[attr] = arr[i]
          end

          self.new(opts)
        else
          self.new
        end
      end
    end

    def all_without_nil
      if self.presence.nil?
        all
      else
        all.select{|a| a.send(self.presence).present? }
      end
    end

    def redis_key
      "app:#{self.name.underscore}:set"
    end

  end

end
