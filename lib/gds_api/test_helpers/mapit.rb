module GdsApi
  module TestHelpers
    module Mapit
      MAPIT_ENDPOINT = Plek.current.find("mapit")

      def stub_mapit_has_a_postcode(postcode, coords)
        response = {
          "wgs84_lat" => coords.first,
          "wgs84_lon" => coords.last,
          "postcode" => postcode,
        }

        stub_request(:get, "#{MAPIT_ENDPOINT}/postcode/" + postcode.tr(" ", "+") + ".json")
          .to_return(body: response.to_json, status: 200)
        stub_request(:get, "#{MAPIT_ENDPOINT}/postcode/partial/" + postcode.split(" ").first + ".json")
          .to_return(body: response.to_json, status: 200)
      end

      def stub_mapit_has_a_postcode_and_areas(postcode, coords, areas)
        response = {
          "wgs84_lat" => coords.first,
          "wgs84_lon" => coords.last,
          "postcode" => postcode,
        }

        area_response = Hash[areas.map.with_index do |area, i|
          [i,
           {
             "codes" => {
               "ons" => area["ons"],
               "gss" => area["gss"],
               "govuk_slug" => area["govuk_slug"],
             },
             "name" => area["name"],
             "type" => area["type"],
             "country_name" => area["country_name"],
           }]
        end]

        stub_request(:get, "#{MAPIT_ENDPOINT}/postcode/" + postcode.tr(" ", "+") + ".json")
          .to_return(body: response.merge("areas" => area_response).to_json, status: 200)
        stub_request(:get, "#{MAPIT_ENDPOINT}/postcode/partial/" + postcode.split(" ").first + ".json")
          .to_return(body: response.to_json, status: 200)
      end

      def stub_mapit_does_not_have_a_postcode(postcode)
        stub_request(:get, "#{MAPIT_ENDPOINT}/postcode/" + postcode.tr(" ", "+") + ".json")
          .to_return(body: { "code" => 404, "error" => "No Postcode matches the given query." }.to_json, status: 404)
      end

      def stub_mapit_does_not_have_a_bad_postcode(postcode)
        stub_request(:get, "#{MAPIT_ENDPOINT}/postcode/" + postcode.tr(" ", "+") + ".json")
          .to_return(body: { "code" => 400, "error" => "Postcode '#{postcode}' is not valid." }.to_json, status: 400)
      end

      def stub_mapit_has_areas(area_type, areas)
        stub_request(:get, "#{MAPIT_ENDPOINT}/areas/" + area_type + ".json")
          .to_return(body: areas.to_json, status: 200)
      end

      def stub_mapit_does_not_have_areas(area_type)
        stub_request(:get, "#{MAPIT_ENDPOINT}/areas/" + area_type + ".json")
          .to_return(body: [].to_json, status: 200)
      end

      def stub_mapit_has_area_for_code(code_type, code, area)
        stub_request(:get, "#{MAPIT_ENDPOINT}/code/#{code_type}/#{code}.json")
          .to_return(body: area.to_json, status: 200)
      end

      def stub_mapit_does_not_have_area_for_code(code_type, code)
        stub_request(:get, "#{MAPIT_ENDPOINT}/code/#{code_type}/#{code}.json")
        .to_return(body: { "code" => 404, "error" => "No areas were found that matched code #{code_type} = #{code}." }.to_json, status: 404)
      end
    end
  end
end
