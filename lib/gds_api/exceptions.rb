module GdsApi
  class BaseError < StandardError
  end

  class EndpointNotFound < BaseError
  end

  class TimedOutException < BaseError
  end

  class HTTPErrorResponse < BaseError
    attr_accessor :code

    def initialize(code)
      @code = code
    end
  end

  module ExceptionHandling
    def ignoring(exception, &block)
      yield
    rescue exception
      # Discard the exception
    end
  end
end
