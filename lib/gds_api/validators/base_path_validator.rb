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
        errors = []
        errors << "Path cannot be nil" if base_path.nil?
        errors << "Path must start with a /" if no_leading_slash?
        errors << "Path cannot be longer than #{MAX_PATH_LENGTH} characters" if too_long?
        errors << "Path contains runs of . and or / characters, which could be penetration attempts" if potential_path_traversal?
        errors << "Path cannot end with a ." if ends_with_a_period?
        errors << "Path contains characters that are not lowercase letters, numbers, -, ., or /" if invalid_chars?
        errors
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
