require "test_helper"
require "gds_api/licence_application"
require "gds_api/test_helpers/licence_application"

class LicenceApplicationApiTest < MiniTest::Unit::TestCase
  include GdsApi::TestHelpers::LicenceApplication

  def setup
    @core_url = LICENCE_APPLICATION_ENDPOINT
  end

  def api
    GdsApi::LicenceApplication.new "test"
  end

  def test_should_not_be_nil
    assert_equal false, api.nil?
  end

  def test_should_return_list_of_licences
    stub_request(:get, "#{@core_url}/api/licences").
      with(headers: GdsApi::JsonClient::DEFAULT_REQUEST_HEADERS).
      to_return(:status => 200,
                :body => <<-EOS
[
   {
      "code":"1324-5-1",
      "name":"Land drainage consents",
      "legislation":[
         "Land Drainage Act 1991"
      ]
   },
   {
      "code":"695-5-1",
      "name":"Skip operator licence",
      "legislation":[
         "Highways Act 1980, Section 139"
      ]
   },
   {
      "code":"1251-4-1",
      "name":"Residential care homes",
      "legislation":[
         "Health and Personal Social Services (Quality, Improvement and Regulation) (Northern Ireland) Order 2003"
      ]
   }
]
EOS
)

    land_drainage = {
      "code" => "1324-5-1",
      "name" => "Land drainage consents",
      "legislation" => ["Land Drainage Act 1991"],
    }

    assert_includes api.all_licences, land_drainage
  end

  def test_should_return_nil_if_id_nil
    assert_nil api.details_for_licence(nil)
  end

  def test_should_return_an_error_message_if_licence_is_unrecognised
    stub_request(:get, "#{@core_url}/api/licence/bloop").
      with(headers: GdsApi::JsonClient::DEFAULT_REQUEST_HEADERS).
      to_return(status: 404, body: "{\"error\": [\"Unrecognised Licence Id: bloop\"]}")

    assert_raises GdsApi::HTTPNotFound do
      api.details_for_licence("bloop")
    end
  end

  def test_should_provide_full_licence_details_for_canonical_id
    licence_exists('590001', {"isLocationSpecific" => true, "geographicalAvailability" => ["England","Wales"], "issuingAuthorities" => []})

    expected = {
      "isLocationSpecific" => true,
      "geographicalAvailability" => ["England", "Wales"],
      "issuingAuthorities" => []
    }

    assert_equal expected, api.details_for_licence("590001").to_hash
  end

  def test_should_return_an_error_message_for_bad_snac_code_entry
    stub_request(:get, "#{@core_url}/api/licence/590001/bleep").
      with(headers: GdsApi::JsonClient::DEFAULT_REQUEST_HEADERS).
      to_return(status: 404,
                body: "{\"error\": \"No authorities found for the licence 590001 and for the snacCode bleep\"}")

    assert_raises GdsApi::HTTPNotFound do
      api.details_for_licence("590001", "bleep")
    end
  end

  def test_should_return_error_messages_for_bad_licence_id_and_snac_code
    stub_request(:get, "#{@core_url}/api/licence/bloop/bleep").
      with(headers: GdsApi::JsonClient::DEFAULT_REQUEST_HEADERS).
      to_return(status: 404,
                body: "{\"error\": \"No authorities found for the licence bloop and for the snacCode bleep\"}")

    assert_raises GdsApi::HTTPNotFound do
      api.details_for_licence("bloop", "bleep")
    end
  end

  def test_should_return_error_message_to_pick_a_relevant_snac_code_for_the_provided_licence_id
    stub_request(:get, "#{@core_url}/api/licence/590001/sw10").
      with(headers: GdsApi::JsonClient::DEFAULT_REQUEST_HEADERS).
      to_return(status: 404,
                body: "{\"error\": \"No authorities found for the licence 590001 and for the snacCode sw10\"}")

    assert_raises GdsApi::HTTPNotFound do
      api.details_for_licence("590001", "sw10")
    end
  end

  def test_should_return_full_licence_details_with_location_specific_information
    stub_request(:get, "#{@core_url}/api/licence/866-5-1/00AA").
      with(headers: GdsApi::JsonClient::DEFAULT_REQUEST_HEADERS).
      to_return(status: 200,
                body: <<-EOS
{
   "isLocationSpecific":true,
   "geographicalAvailability":[
      "England",
      "Wales"
   ],
   "issuingAuthorities":[
      {
         "authorityName":"City of London",
         "authorityInteractions":{
            "apply":[
               {
                  "url":"https://www.gov.uk/motor-salvage-operator-registration/city-of-london/apply-1",
                  "usesLicensify":true,
                  "description":"Application to register as a motor salvage operator",
                  "payment":"none"
               }
            ],
            "renew":[
               {
                  "url":"https://www.gov.uk/motor-salvage-operator-registration/city-of-london/renew-1",
                  "usesLicensify":true,
                  "description":"Application to renew a registration as motor salvage operator",
                  "payment":"none"
               }
            ],
            "change":[
               {
                  "url":"https://www.gov.uk/motor-salvage-operator-registration/city-of-london/change-1",
                  "usesLicensify":true,
                  "description":"Application to change a registration as motor salvage operator",
                  "payment":"none"
               },
               {
                  "url":"https://www.gov.uk/motor-salvage-operator-registration/city-of-london/change-2",
                  "usesLicensify":true,
                  "description":"Application to surrender a registration as motor salvage operator",
                  "payment":"none"
               }
            ]
         }
      }
   ]
}
EOS
)

    response = api.details_for_licence("866-5-1", "00AA")

    assert_equal true, response["isLocationSpecific"]

    assert_includes response["issuingAuthorities"][0]["authorityInteractions"]["apply"], {
      "url" => "https://www.gov.uk/motor-salvage-operator-registration/city-of-london/apply-1",
      "usesLicensify" => true,
      "description" => "Application to register as a motor salvage operator",
      "payment" => "none"
    }
  end
end
