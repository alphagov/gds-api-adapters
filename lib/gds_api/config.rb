module GdsApi
  def self.configure
    yield(config)
  end

  def self.config
    @config ||= Config.new
  end

  class Config
    # Always raise an `HTTPNotFound` exception when the server returns 404 or an
    # `HTTPGone` when the server returns 410. This avoids nil-errors in your
    # code and makes debugging easier.
    #
    # Currently defaults to true.
    #
    # This configuration will be removed on December 1st, 2016. Please make sure
    # you upgrade gds-api-adapters to the latest version and avoid configuring
    # it on your client application.
    def always_raise_for_not_found
      return true if @always_raise_for_not_found.nil?

      @always_raise_for_not_found
    end

    def always_raise_for_not_found=(value)
      warn <<-doc

DEPRECATION NOTICE: Please delete any instances of
`GdsApi.config.always_raise_for_not_found=` from your codebase to make
sure all 404 or 410 responses raise an exception.

This configuration option will be be removed. Raising exceptions is now
the default behaviour and it won't be possible to opt-out from December
1st, 2016.

Called from: #{caller[2]}

      doc

      @always_raise_for_not_found = value
    end

    # Set to true to make `GdsApi::Response` behave like a simple hash, instead
    # of an OpenStruct. This will prevent nil-errors.
    #
    # This configuration allows some time to upgrade - you should opt-in to this
    # behaviour now. We'll change this to default to true on October 1st, 2016
    # and remove the option entirely on December 1st, 2016.
    attr_accessor :hash_response_for_requests
  end
end
