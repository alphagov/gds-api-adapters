module GdsApi
  def self.configure
    yield(config)
  end

  def self.config
    @config ||= Config.new
  end

  class Config
    # Always raise a `HTTPNotFound` exception when the server returns 404 or
    # 410. This avoids nil-errors in your code and makes debugging easier.
    #
    # Currently defaults to false.
    #
    # This configuration allows some time to upgrade - you should opt-in to this
    # behaviour now. We'll change this to default to true on October 1st, 2016
    # and remove the option entirely on December 1st, 2016.
    attr_accessor :always_raise_for_not_found
  end
end
