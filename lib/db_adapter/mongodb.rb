module DbAdapter
  class Mongodb
    attr_reader :klass
    def initialize(klass)
      @klass = klass
    end

    def find(id)
      klass.find(id)
    end

    def find_by(conditions={})
      klass.find_by(conditions)
    end

    def where(conditions={})
      klass.where(conditions)
    end
  end
end
