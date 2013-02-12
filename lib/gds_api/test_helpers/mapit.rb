module GdsApi
  module TestHelpers
    module Mapit

      MAPIT_ENDPOINT = Plek.current.find('mapit')

      def mapit_has_a_postcode(postcode, coords)
        response = {
          "wgs84_lat" => coords.first,
          "wgs84_lon" => coords.last,
          "postcode"  => postcode
        }

        stub_request(:get, "#{MAPIT_ENDPOINT}/postcode/" + postcode.gsub(' ','+') + ".json")
          .to_return(:body => response.to_json, :status => 200)
        stub_request(:get, "#{MAPIT_ENDPOINT}/postcode/partial/" + postcode.split(' ').first + ".json")
          .to_return(:body => response.to_json, :status => 200)
      end

      def mapit_has_a_postcode_and_areas(postcode, coords, areas)
        response = {
          "wgs84_lat" => coords.first,
          "wgs84_lon" => coords.last,
          "postcode"  => postcode
        }

        area_response = Hash[areas.map.with_index {|area, i|
          [i, {
            'codes' => {
              'ons' => area['ons'],
              'gss' => area['gss']
            },
            'name' => area['name'],
            'type' => area['type']
          }]
        }]

        stub_request(:get, "#{MAPIT_ENDPOINT}/postcode/" + postcode.gsub(' ','+') + ".json")
          .to_return(:body => response.merge({'areas' => area_response}).to_json, :status => 200)
        stub_request(:get, "#{MAPIT_ENDPOINT}/postcode/partial/" + postcode.split(' ').first + ".json")
          .to_return(:body => response.to_json, :status => 200)
      end

      def mapit_does_not_have_a_postcode(postcode)
        stub_request(:get, "#{MAPIT_ENDPOINT}/postcode/" + postcode.gsub(' ','+') + ".json")
          .to_return(:body => { "code" => 404, "error" => "No Postcode matches the given query." }.to_json, :status => 404)
      end

      def mapit_does_not_have_a_bad_postcode(postcode)
        stub_request(:get, "#{MAPIT_ENDPOINT}/postcode/" + postcode.gsub(' ','+') + ".json")
          .to_return(:body => { "code" => 400, "error" => "Postcode '#{postcode}' is not valid." }.to_json, :status => 400)
      end

    end
  end
end
