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

  class NoBearerToken < BaseError; end

  module ExceptionHandling
    def ignoring(exception, &block)
      yield
    rescue exception
      # Discard the exception
    end
  end
end
