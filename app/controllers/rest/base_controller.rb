class Rest::BaseController < ApplicationController
  skip_before_action :verify_authenticity_token

  RestParamsError = Class.new StandardError
  rescue_from StandardError do |e|
    error_response(e.message)
  end
  rescue_from RestParamsError do |e|
    error_response("缺少必要参数")
  end

  def requires(*attrs)
    raise RestParamsError unless attrs.reduce(true) { |i, j| i && params[j.to_sym] }
  end

  def error_response(msg)
    error_result = {status: 0, error: msg}
    $rest_logger.error("params: #{params}, response: #{error_result}")
    render json: error_result
  end

  def present(data)
    result = {status: 1, data: data}
    $rest_logger.info("params: #{params}, response: #{result}")
    render json: result
  end
end
