require "test_helper"
require "gds_api/places_manager"

class PlacesManagerApiTest < Minitest::Test
  ROOT = Plek.find("places-manager")
  LATITUDE = 52.1327584352089
  LONGITUDE = -0.4702813074674147

  def api_client
    GdsApi::PlacesManager.new(ROOT)
  end

  def dummy_place
    {
      "access_notes" => nil,
      "address1" => "Cauldwell Street",
      "address2" => "Bedford",
      "fax" => nil,
      "general_notes" => nil,
      "geocode_error" => nil,
      "location" => { "latitude" => LATITUDE, "longitude" => LONGITUDE },
      "name" => "Town Hall",
      "phone" => nil,
      "postcode" => "MK42 9AP",
      "source_address" => "Town Hall, Cauldwell Street, Bedford",
      "text_phone" => nil,
      "town" => nil,
      "url" => "http://www.bedford.gov.uk/advice_and_benefits/registration_service.aspx",
    }
  end

  def dummy_place_response(place_array)
    {
      "status" => "ok",
      "contents" => "places",
      "places" => place_array,
    }
  end

  def test_search_for_places
    c = api_client
    url = "#{ROOT}/places/wibble.json?limit=5&lat=52&lng=0"
    c.expects(:get_json).with(url).returns(dummy_place_response([dummy_place]))
    output = c.places("wibble", 52, 0)

    places = output["places"]
    assert_equal 1, places.size
    place = places[0]
    assert_equal LATITUDE, place["location"]["latitude"]
    assert_equal LONGITUDE, place["location"]["longitude"]
  end

  def test_nil_location
    # Test behaviour when the location field is nil
    c = api_client
    url = "#{ROOT}/places/wibble.json?limit=5&lat=52&lng=0"
    place_info = dummy_place.merge("location" => nil)
    c.expects(:get_json).with(url).returns(dummy_place_response([place_info]))
    output = c.places("wibble", 52, 0)
    places = output["places"]

    assert_equal 1, places.size
    place = places[0]
    assert_nil place["latitude"]
    assert_nil place["longitude"]
  end

  def test_hash_location
    # Test behaviour when the location field is a longitude/latitude hash
    c = api_client
    url = "#{ROOT}/places/wibble.json?limit=5&lat=52&lng=0"
    place_info = dummy_place.merge(
      "location" => { "longitude" => LONGITUDE, "latitude" => LATITUDE },
    )
    c.expects(:get_json).with(url).returns(dummy_place_response([place_info]))
    output = c.places("wibble", 52, 0)
    places = output["places"]

    assert_equal 1, places.size
    place = places[0]
    assert_equal LATITUDE, place["location"]["latitude"]
    assert_equal LONGITUDE, place["location"]["longitude"]
  end

  def test_postcode_search
    # Test behaviour when searching by postcode
    c = api_client
    url = "#{ROOT}/places/wibble.json?limit=5&postcode=MK42+9AA"
    c.expects(:get_json).with(url).returns(dummy_place_response([dummy_place]))
    output = c.places_for_postcode("wibble", "MK42 9AA")
    places = output["places"]

    assert_equal 1, places.size
  end

  def test_postcode_with_local_authority_search
    # Test behaviour when searching by postcode
    c = api_client
    url = "#{ROOT}/places/wibble.json?limit=10&postcode=MK42+9AA&local_authority_slug=broadlands"
    c.expects(:get_json).with(url).returns(dummy_place_response([dummy_place]))
    output = c.places_for_postcode("wibble", "MK42 9AA", 10, "broadlands")
    places = output["places"]

    assert_equal 1, places.size
  end

  def test_invalid_postcode_search
    # Test behaviour when searching by invalid postcode
    c = api_client
    url = "#{ROOT}/places/wibble.json?limit=5&postcode=MK99+9AA"
    c.expects(:get_json).with(url).raises(GdsApi::HTTPErrorResponse.new(400))
    assert_raises GdsApi::HTTPErrorResponse do
      c.places_for_postcode("wibble", "MK99 9AA")
    end
  end

  def test_places_kml
    kml_body = <<~KML
      <?xml version="1.0" encoding="UTF-8"?>
      <kml xmlns="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
        <Document>
          <name>DVLA Offices</name>
          <Placemark>
            <atom:link/>
            <name>DVLA Aberdeen local office</name>
            <description>For enquiries about vehicles: 0300 790 6802 (Textphone minicom users 0300 123 1279).For enquiries about driving licences: 0300 790 6801 (Textphone minicom users 0300 123 1278).Please note, all calls are handled initially by our call centre based in Swansea</description>
            <address>Greyfriars House, Gallowgate, Aberdeen, AB10 1WG, UK</address>
            <Point>
              <coordinates>-2.0971999005177566,57.150739708305785,0</coordinates>
            </Point>
          </Placemark>
        </document>
      </kml>
    KML

    stub_request(:get, "#{ROOT}/places/test.kml")
      .with(headers: GdsApi::JsonClient.default_request_headers)
      .to_return(status: 200, body: kml_body)

    response_body = api_client.places_kml("test")
    assert_equal kml_body, response_body
  end
end
