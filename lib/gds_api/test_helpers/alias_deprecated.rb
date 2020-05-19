module GdsApi
  module TestHelpers
    module AliasDeprecated
      def alias_deprecated(deprecated_method, replacement_method)
        class_name = name
        define_method(deprecated_method) do |*args, &block|
          warn "##{deprecated_method} is deprecated on #{class_name} and will be removed in a future version. Use ##{replacement_method} instead"
          public_send(replacement_method, *args, &block)
        end
      end
    end
  end
end
