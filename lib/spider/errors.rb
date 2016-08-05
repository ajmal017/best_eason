module Spider
  class Error < RuntimeError; end
  class ConfigurationError < Error; end
  class MissAttributesError < Error; end
  class HTTPError < Error; attr_accessor :original_error; end
  class SourceCodeError < Error; end
end