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
    # Currently defaults to false, but will be enabled by default in the future.
    attr_accessor :always_raise_for_not_found
  end
end
