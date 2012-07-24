require "test_helper"
require "gds_api/licence_application"

class LicenceApplicationApiTest < MiniTest::Unit::TestCase

  def api
    GdsApi::LicenceApplication.new "test"
  end

  def test_should_not_be_nil
    assert_equal false, api.nil?
  end

  def test_should_return_nil_if_id_nil
    assert_equal nil, api.details_for_licence(nil)
  end

  def test_should_return_an_error_message_if_licence_is_unrecognised
    stub_request(:get, "https://licenceapplication.test.alphagov.co.uk/api/bloop").
      with(headers: GdsApi::JsonClient::REQUEST_HEADERS).
      to_return(status: 404, body: "{\"error\": [\"Unrecognised Licence Id: bloop\"]}")

    expected = {"error" => ["Unrecognised Licence Id: bloop"]}

    assert_equal expected, api.details_for_licence("bloop")
  end

  def test_should_provide_full_licence_details_for_canonical_id
    stub_request(:get, "https://licenceapplication.test.alphagov.co.uk/api/590001").
      with(headers: GdsApi::JsonClient::REQUEST_HEADERS).
      to_return(status: 200, body: "{\"issuingAuthorityType\":\"non-geographical\",\"geographicalAvailability\":\"England\",\"issuingAuthorities\":[{\"authorityName\":\"Authority Name\",\"interactions\":{\"apply\":{\"url\":\"www.gov.uk\",\"usesLicensify\":true,\"description\":\"Custom description\",\"payment\":\"none\",\"paymentAmount\":0}}}]}")

    expected = {
      "issuingAuthorityType" => "non-geographical",
      "geographicalAvailability" => "England",
      "issuingAuthorities" => [{"authorityName" => "Authority Name",
                                 "interactions" => {
                                   "apply" => {
                                     "url" => "www.gov.uk",
                                     "usesLicensify" => true,
                                     "description" => "Custom description",
                                     "payment" => "none",
                                     "paymentAmount" => 0}
                                 }
                               }]
    }

    assert_equal expected, api.details_for_licence("590001")
  end

  def test_should_return_an_error_message_for_bad_snac_code_entry
    stub_request(:get, "https://licenceapplication.test.alphagov.co.uk/api/590001/bleep").
      with(headers: GdsApi::JsonClient::REQUEST_HEADERS).
      to_return(status: 404, body: "{\"error\": [\"Unrecognised SNAC: bleep\"]}")

    expected = {"error" => ["Unrecognised SNAC: bleep"]}

    assert_equal expected, api.details_for_licence("590001", "bleep")
  end

  def test_should_return_error_messages_for_bad_licence_id_and_snac_code
    stub_request(:get, "https://licenceapplication.test.alphagov.co.uk/api/bloop/bleep").
      with(headers: GdsApi::JsonClient::REQUEST_HEADERS).
      to_return(status: 404, body: "{\"error\": [\"Unrecognised Licence Id: bloop\", \"Unrecognised SNAC: bleep\"]}")

    expected = {"error" => ["Unrecognised Licence Id: bloop",
                            "Unrecognised SNAC: bleep"]}

    assert_equal expected, api.details_for_licence("bloop", "bleep")
  end

  def test_should_return_error_message_to_pick_a_relevant_snac_code_for_the_provided_licence_id
    stub_request(:get, "https://licenceapplication.test.alphagov.co.uk/api/590001/sw10").
      with(headers: GdsApi::JsonClient::REQUEST_HEADERS).
      to_return(status: 200, body: "{\"error\": [\"Licence not available in the provided snac area\"], \"geographicalAvailability\": [\"Scotland\", \"NI\"]}")

    expected = {
      "error" => ["Licence not available in the provided snac area"],
      "geographicalAvailability" => ["Scotland", "NI"]
    }

    assert_equal expected, api.details_for_licence("590001", "sw10")
  end
end
