module GdsApi
  module Validators
    class BasePathValidator
      MAX_PATH_LENGTH = 512

      # The RFC-192 character set for base paths: a-z 0-9 . - /
      RFC_192_CHARACTER_SET = /^([\/a-z0-9.-])+$/

      # As above but permitting underscores
      UNDERSCORE_TOLERANT_CHARACTER_SET = /^([\/a-z0-9._-])+$/

      attr_reader :base_path

      def initialize(base_path, allow_underscores: false)
        @base_path = base_path
        @allow_underscores = allow_underscores
      end

      def valid?
        return true unless base_path

        !(no_leading_slash? || too_long? || potential_path_traversal? || ends_with_a_period? || invalid_chars?)
      end

      def errors
        return {} unless base_path

        errors = []
        errors << [:base_path_invalid, "must start with a /"] if no_leading_slash?
        errors << [:base_path_too_long, "must not be longer than #{MAX_PATH_LENGTH} bytes"] if too_long?
        errors << [:base_path_invalid, "must not include runs of . and or / characters, which could be penetration attempts"] if potential_path_traversal?
        errors << [:base_path_invalid, "must not end with a ."] if ends_with_a_period?
        errors << [:base_path_invalid, "must not include characters that are not lowercase letters, numbers, -, ., #{'_, ' if allow_underscores?}or /"] if invalid_chars?

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
        base_path !~ allowed_chars_regex
      end

      def allowed_chars_regex
        return UNDERSCORE_TOLERANT_CHARACTER_SET if allow_underscores?

        RFC_192_CHARACTER_SET
      end

      def allow_underscores?
        @allow_underscores
      end
    end
  end
end
