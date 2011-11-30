require 'test_helper'
require 'gds_api/contactotron'

class ContactotronApiTest < MiniTest::Unit::TestCase
  def api
    GdsApi::Contactotron.new
  end

  def test_should_fetch_and_parse_JSON_into_ostruct
    uri = "http://contactotron.environment/contacts/1"
    stub_request(:get, uri).
      to_return(:status => 200, :body => '{"detail":"value"}')
    assert_equal OpenStruct, api.contact_for_uri(uri).class
  end
end
