module BodyFormatter
  def self.call(object, env)

    return object.to_json if object.is_a?(Hash) and object.has_key?(:swaggerVersion)

    result = { status: 1 }

    result[:data] = object
    if object.is_a?(Hash) && object.has_key?(:data)
      result[:data] = object[:data]
      result[:ext] = %i[total_pages page per_page total_entries].reduce({}){|l,n| l[n] = object[n] if object.has_key?(n); l } || {}
    end

    # 去除nil值
    result[:data].try(:compact!) if result[:data].is_a?(Array)

    result[:data] = {} if result[:data].nil? || result[:data] == true

    result.as_json.to_json

  ensure
    $api_logger.info("url: #{env['ORIGINAL_FULLPATH']}, request_form: #{env['rack.request.form_vars']}")
  end
end

# 目前只有K线走此方法
module JsonStringFormatter
  def self.call(object, env)

    # 线上大的json解析速度太慢,直接操作字符串,加快速度
    if object.is_a?(String) && object.start_with?("[")
      result = { status: 1, data: [] }.to_json
      return object.insert(0, result[0..18]).insert(-1, result[-1])
    end

    BodyFormatter.call(object, env)
  end
end

module ErrorFormatter
  def self.call(message, backtrace, options, env)

    return message.to_json if message.is_a?(Hash) and message.has_key?(:swaggerVersion)

    result = {
      status: 0,
      error: message
    }

    result.as_json.to_json
  ensure
    $api_logger.error("url: #{env['ORIGINAL_FULLPATH']}, error: #{result}, request_form: #{env['rack.request.form_vars']}")
  end
end
