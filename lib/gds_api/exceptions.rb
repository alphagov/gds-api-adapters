module GdsApi
  # Abstract error class
  class BaseError < StandardError
  end

  class EndpointNotFound < BaseError
  end

  class TimedOutException < BaseError
  end

  # Superclass for all 4XX and 5XX errors
  class HTTPErrorResponse < BaseError
    attr_accessor :code, :error_details

    def initialize(code, message = nil, error_details = nil, request_body = nil)
      super(message)
      @code = code
      @error_details = error_details
      @request_body = request_body
    end
  end

  # Superclass & fallback for all 4XX errors
  class HTTPClientError < HTTPErrorResponse
  end

  # Superclass & fallback for all 5XX errors
  class HTTPServerError < HTTPErrorResponse
  end

  class HTTPInternalServerError < HTTPServerError
  end

  class HTTPBadGateway < HTTPServerError
  end

  class HTTPUnavailable < HTTPServerError
  end

  class HTTPGatewayTimeout < HTTPServerError
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

  class HTTPUnprocessableEntity < HTTPClientError
  end

  class InvalidUrl < BaseError; end

  class NoBearerToken < BaseError; end

  module ExceptionHandling
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
      when 422
        GdsApi::HTTPUnprocessableEntity
      when (400..499)
        GdsApi::HTTPClientError
      when 500
        GdsApi::HTTPInternalServerError
      when 502
        GdsApi::HTTPBadGateway
      when 503
        GdsApi::HTTPUnavailable
      when 504
        GdsApi::HTTPGatewayTimeout
      when (500..599)
        GdsApi::HTTPServerError
      else
        GdsApi::HTTPErrorResponse
      end
    end
  end
end
