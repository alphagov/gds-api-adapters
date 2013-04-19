module GdsApi
  class NullCache
    def [](k)
      nil
    end

    def []=(k, v)
    end

    def store(k, v, args={})
    end
  end
end
