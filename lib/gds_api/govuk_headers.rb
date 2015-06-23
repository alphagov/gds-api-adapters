module GdsApi
  class GovukHeaders
    class << self
      def set_header(header_name, value)
        header_data[header_name] = value
      end

      def headers
        header_data.select {|k, v| !(v.nil? || v.empty?) }
      end

      private

      def header_data
        Thread.current[:headers] ||= {}
      end

    end
  end
end

