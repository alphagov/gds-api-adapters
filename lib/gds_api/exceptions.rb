module GdsApi
  # Abstract error class
  class BaseError < StandardError
    # Give Sentry extra context about this event
    # https://docs.sentry.io/clients/ruby/context/
    def raven_context
      {
        # Make Sentry group exceptions by type instead of message, so all
        # exceptions like `GdsApi::TimedOutException` will get grouped as one
        # error and not an error per URL.
        fingerprint: [self.class.name],
      }
    end
  end

  class EndpointNotFound < BaseError; end
  class TimedOutException < BaseError; end
  class InvalidUrl < BaseError; end
  class SocketErrorException < BaseError; end

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
  class HTTPClientError < HTTPErrorResponse; end
  class HTTPIntermittentClientError < HTTPClientError; end

  class HTTPNotFound < HTTPClientError; end
  class HTTPGone < HTTPClientError; end
  class HTTPPayloadTooLarge < HTTPClientError; end
  class HTTPUnauthorized < HTTPClientError; end
  class HTTPForbidden < HTTPClientError; end
  class HTTPConflict < HTTPClientError; end
  class HTTPUnprocessableEntity < HTTPClientError; end
  class HTTPTooManyRequests < HTTPIntermittentClientError; end

  # Superclass & fallback for all 5XX errors
  class HTTPServerError < HTTPErrorResponse; end
  class HTTPIntermittentServerError < HTTPServerError; end

  class HTTPInternalServerError < HTTPServerError; end
  class HTTPBadGateway < HTTPIntermittentServerError; end
  class HTTPUnavailable < HTTPIntermittentServerError; end
  class HTTPGatewayTimeout < HTTPIntermittentServerError; end

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
      when 413
        GdsApi::HTTPPayloadTooLarge
      when 422
        GdsApi::HTTPUnprocessableEntity
      when 429
        GdsApi::HTTPTooManyRequests
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
