
module GdsApi
  module TestHelpers
    module ContentItemHelpers

      def content_item_for_base_path(base_path)
        {
          "title" => titleize_base_path(base_path),
          "description" => "Description for #{base_path}",
          "format" => "guide",
          "need_ids" => ["100001"],
          "public_updated_at" => "2014-05-06T12:01:00+00:00",
          # base_path is added in as necessary (ie for content-store GET responses)
          # "base_path" => base_path,
          "details" => {
            "body" => "Some content for #{base_path}",
          }
        }
      end

      def titleize_base_path(base_path, options = {})
        if options[:title_case]
          base_path.gsub("-", " ").gsub(/\b./) {|m| m.upcase }
        else
          base_path.gsub(%r{[-/]}, " ").strip.capitalize
        end
      end
    end
  end
end
