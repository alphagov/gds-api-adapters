module GdsApi
  module Validators
    class BasePathValidator
      MAX_PATH_LENGTH = 512

      attr_reader :base_path

      def initialize(base_path)
        @base_path = base_path
      end

      def valid?
        !(base_path.nil? || no_leading_slash? || too_long? || potential_path_traversal? || ends_with_a_period? || invalid_chars?)
      end

      def errors
        return { base_path_invalid: ["must not be nil"] } if base_path.nil?

        errors = []
        errors << [:base_path_invalid, "must start with a /"] if no_leading_slash?
        errors << [:base_path_too_long, "must not be longer than #{MAX_PATH_LENGTH} bytes"] if too_long?
        errors << [:base_path_invalid, "must not include runs of . and or / characters, which could be penetration attempts"] if potential_path_traversal?
        errors << [:base_path_invalid, "must not end with a ."] if ends_with_a_period?
        errors << [:base_path_invalid, "must not include characters that are not lowercase letters, numbers, -, ., or /"] if invalid_chars?

        errors.each_with_object({}) do |err, memo|
          memo[err[0]] ||= []
          memo[err[0]] << err[1]
        end
      end

    private

      def no_leading_slash?
        base_path[0] != "/"
      end

      def too_long?
        base_path.length > MAX_PATH_LENGTH
      end

      def potential_path_traversal?
        base_path =~ /([\/.]{2,})/
      end

      def ends_with_a_period?
        base_path[-1] == "."
      end

      def invalid_chars?
        base_path !~ /^([\/a-z0-9.-])+$/
      end
    end
  end
end
