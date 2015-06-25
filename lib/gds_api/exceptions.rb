module GdsApi
  class BaseError < StandardError
  end

  class EndpointNotFound < BaseError
  end

  class TimedOutException < BaseError
  end

  class TooManyRedirects < BaseError
  end

  class HTTPErrorResponse < BaseError
    attr_accessor :code, :error_details

    def initialize(code, message = nil, error_details = nil)
      super(message)
      @code = code
      @error_details = error_details
    end
  end

  class HTTPClientError < HTTPErrorResponse
  end

  class HTTPServerError < HTTPErrorResponse
  end

  class HTTPNotFound < HTTPClientError
  end

  class HTTPGone < HTTPClientError
  end

  class HTTPForbidden < HTTPClientError
  end

  class NoBearerToken < BaseError; end

  module ExceptionHandling
    def ignoring(exception_or_exceptions, &block)
      yield
    rescue *exception_or_exceptions
      # Discard the exception
    end

    def ignoring_missing(&block)
      ignoring([HTTPNotFound, HTTPGone], &block)
    end

    def build_specific_http_error(error, url, details = nil)
      message = "url: #{url}\n#{error.http_body}"
      code = error.http_code

      case code
      when 403
        GdsApi::HTTPForbidden.new(code, message, details)
      when 404
        GdsApi::HTTPNotFound.new(code, message, details)
      when 410
        GdsApi::HTTPGone.new(code, message, details)
      when (400..499)
        GdsApi::HTTPClientError.new(code, message, details)
      when (500..599)
        GdsApi::HTTPServerError.new(code, message, details)
      else
        GdsApi::HTTPErrorResponse.new(code, message, details)
      end
    end
  end
end
