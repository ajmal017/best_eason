module Entities
  class Base < Grape::Entity
    # 注意！！！
    # format_with 不能对包含代码块的属性进行解析，
    # 上述情况请自行处理
    format_with(:to_f) { |dt| dt.nil? ? dt : dt.to_f }
    format_with(:to_i) { |dt| dt.to_i }
    format_with(:date_format) { |dt| dt.to_s }
    format_with(:boolean_to_int) { |dt| dt ? 1 : 0 }

    def format_method_with_nil(data, method, format_method)
      result = data.try(method)
      result.present? ? result.try(format_method) : result
    end

    def format_float_with_nil(data, method)
      format_method_with_nil(data, method, :to_f)
    end

    def self.available_exposures(*aes)
      available_keys = aes.map(&:to_sym)
      exposures.keys.each { |k, v| unexpose k unless available_keys.include? k }
    end

  end
end
