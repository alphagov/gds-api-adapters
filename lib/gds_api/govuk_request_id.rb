module GdsApi
  class GovukRequestId
    class << self
      def set?
        !(value.nil? || value.empty?)
      end

      def value
        Thread.current[:govuk_request_id]
      end

      def value=(new_id)
        Thread.current[:govuk_request_id] = new_id
      end
    end
  end
end
