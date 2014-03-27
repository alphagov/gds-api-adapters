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

    def initialize(code, error_details = nil)
      @code = code
      @error_details = error_details
    end
  end

  class HTTPNotFound < HTTPErrorResponse
  end

  class HTTPGone < HTTPErrorResponse; end

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
  end
end
