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

    def initialize(code, message = nil, error_details = nil, request_body = nil)
      super(message)
      @code = code
      @error_details = error_details
      @request_body = request_body
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

  class HTTPUnauthorized < HTTPClientError
  end

  class HTTPForbidden < HTTPClientError
  end

  class HTTPConflict < HTTPClientError
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

    def build_specific_http_error(error, url, details = nil, request_body = nil)
      message = "URL: #{url}\nResponse body:\n#{error.http_body}\n\nRequest body:\n#{request_body}"
      code = error.http_code
      error_class_for_code(code).new(code, message, details)
    end

    def error_class_for_code(code)
      case code
      when 401
        GdsApi::HTTPUnauthorized
      when 403
        GdsApi::HTTPForbidden
      when 404
        GdsApi::HTTPNotFound
      when 409
        GdsApi::HTTPConflict
      when 410
        GdsApi::HTTPGone
      when (400..499)
        GdsApi::HTTPClientError
      when (500..599)
        GdsApi::HTTPServerError
      else
        GdsApi::HTTPErrorResponse
      end
    end
  end
end
