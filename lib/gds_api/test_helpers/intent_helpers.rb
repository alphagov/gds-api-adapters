module GdsApi
  module TestHelpers
    module IntentHelpers

      def intent_for_base_path(base_path)
        {
          "base_path" => base_path,
          "publish_time" => "2014-05-06T12:01:00+00:00",
        }
      end
    end
  end
end

