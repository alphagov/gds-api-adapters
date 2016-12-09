module GdsApi
  class NullCache
    def [](_k)
      nil
    end

    def []=(k, v)
    end

    def store(k, v, expiry_time = nil)
    end
  end
end
