require "test_helper"
require "gds_api/licence_application"
require "gds_api/test_helpers/licence_application"

class LicenceApplicationApiTest < Minitest::Test
  include GdsApi::TestHelpers::LicenceApplication

  def setup
    @core_url = LICENCE_APPLICATION_ENDPOINT
  end

  def api
    GdsApi::LicenceApplication.new LICENCE_APPLICATION_ENDPOINT
  end

  def test_should_not_be_nil
    assert_equal false, api.nil?
  end

  def test_should_return_list_of_licences
    stub_request(:get, "#{@core_url}/api/licences").
      with(headers: GdsApi::JsonClient.default_request_headers).
      to_return(status: 200,
                body: <<~JSON
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
                JSON
              )

    land_drainage = {
      "code" => "1324-5-1",
      "name" => "Land drainage consents",
      "legislation" => ["Land Drainage Act 1991"],
    }

    assert_includes api.all_licences, land_drainage
  end

  def test_should_return_error_message_if_licences_collection_not_found
    stub_request(:get, "#{@core_url}/api/licences").
      with(headers: GdsApi::JsonClient.default_request_headers).
      to_return(status: 404,
        body: "{\"error\": \"Error\"}")

    assert_raises GdsApi::HTTPNotFound do
      api.all_licences
    end
  end

  def test_should_return_nil_if_id_nil
    assert_nil api.details_for_licence(nil)
  end

  def test_should_raise_if_licence_is_unrecognised
    licence_does_not_exist('bloop')

    assert_raises(GdsApi::HTTPNotFound) do
      api.details_for_licence("bloop")
    end
  end

  def test_should_provide_full_licence_details_for_canonical_id
    licence_exists('590001', "isLocationSpecific" => true, "geographicalAvailability" => %w(England Wales), "issuingAuthorities" => [])

    expected = {
      "isLocationSpecific" => true,
      "geographicalAvailability" => %w(England Wales),
      "issuingAuthorities" => []
    }

    assert_equal expected, api.details_for_licence("590001").to_hash
  end

  def test_should_raise_for_bad_snac_code_entry
    licence_does_not_exist('590001/bleep')

    assert_raises(GdsApi::HTTPNotFound) do
      api.details_for_licence("590001", "bleep")
    end
  end

  def test_should_raise_for_bad_licence_id_and_snac_code
    licence_does_not_exist('bloop/bleep')

    assert_raises(GdsApi::HTTPNotFound) do
      api.details_for_licence("bloop", "bleep")
    end
  end

  def test_should_return_error_message_to_pick_a_relevant_snac_code_for_the_provided_licence_id
    stub_request(:get, "#{@core_url}/api/licence/590001/sw10").
      with(headers: GdsApi::JsonClient.default_request_headers).
      to_return(status: 404,
                body: "{\"error\": \"No authorities found for the licence 590001 and for the snacCode sw10\"}")

    assert_raises(GdsApi::HTTPNotFound) do
      api.details_for_licence("590001", "sw10")
    end
  end

  def test_should_return_full_licence_details_with_location_specific_information
    licence_exists('866-5-1/00AA', <<~JSON
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
    JSON
    )

    response = api.details_for_licence("866-5-1", "00AA")

    assert_equal true, response["isLocationSpecific"]

    assert_includes response["issuingAuthorities"][0]["authorityInteractions"]["apply"], "url" => "https://www.gov.uk/motor-salvage-operator-registration/city-of-london/apply-1",
      "usesLicensify" => true,
      "description" => "Application to register as a motor salvage operator",
      "payment" => "none"
  end

  def test_should_raise_exception_on_timeout
    licence_times_out("866-5-1")

    assert_raises GdsApi::TimedOutException do
      api.details_for_licence("866-5-1")
    end
  end

  def test_should_raise_exception_on_api_error
    licence_returns_error("866-5-1")

    assert_raises GdsApi::HTTPServerError do
      api.details_for_licence("866-5-1")
    end
  end
end
