module GdsApi
  class EndpointNotFound < StandardError
  end

  class TimedOutException < Exception
  end

  class HTTPErrorResponse < StandardError
    attr_accessor :code

    def initialize(code)
      @code = code
    end
  end
end
