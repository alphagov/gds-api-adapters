require 'test_helper'
require 'gds_api/contactotron'
require 'gds_api/test_helpers/contactotron'

class ContactotronApiTest < MiniTest::Unit::TestCase
  include GdsApi::TestHelpers::Contactotron

  def api
    GdsApi::Contactotron.new "test"
  end

  def test_should_fetch_and_parse_JSON_into_ostruct
    uri = "http://contactotron.platform/contacts/1"
    contactotron_has_contact(uri, {details: 'value'})
    assert_equal OpenStruct, api.contact_for_uri(uri).class
  end
end
