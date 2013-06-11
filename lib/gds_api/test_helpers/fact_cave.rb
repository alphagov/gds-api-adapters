module GdsApi
  module TestHelpers
    module FactCave 

      FACT_CAVE_ENDPOINT = Plek.current.find('fact-cave')

      def fact_cave_has_a_fact(slug, atts)
        response = atts.merge({
          "_response_info" => { "status" => "ok" }
        })

        stub_request(:get, "#{FACT_CAVE_ENDPOINT}/facts/#{slug}")
          .to_return(:body => response.to_json, :status => 200)
      end

      def fact_cave_does_not_have_a_fact(slug)
        response = {
          "_response_info" => { "status" => "not found" }
        }

        stub_request(:get, "#{FACT_CAVE_ENDPOINT}/facts/#{slug}")
          .to_return(:body => response.to_json, :status => 404)
      end
    end
  end
end
