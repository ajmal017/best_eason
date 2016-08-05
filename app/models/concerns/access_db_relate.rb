module AccessDbRelate
  extend ActiveSupport::Concern

  included do
    self.attribute_names.grep(/^(.*)able_type$/) { self.make_methods $1 }
  end

  module ClassMethods
    def make_methods(name)
      %w[id type].each do |key|
        define_method "origin_#{name}able_#{key}" do
          return self.send("#{name}able").try("sourceable_#{key}") if self.send("#{name}able_type") == "StaticContent"
          self.send("#{name}able_#{key}").to_s
        end
      end
    end
  end

end
