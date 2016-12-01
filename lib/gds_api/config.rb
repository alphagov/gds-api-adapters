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
  end
end
