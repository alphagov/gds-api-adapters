require 'test_helper'
require 'gds_api/content_api'
require 'gds_api/test_helpers/content_api'

class ContentApiTest < MiniTest::Unit::TestCase
  include GdsApi::TestHelpers::ContentApi

  def api
    GdsApi::ContentApi.new('test')
  end

  def test_sections
    content_api_has_root_sections(["crime"])
    response = api.sections
    first_section = response["results"][0]
    assert_equal "http://contentapi.test.gov.uk/tags/crime.json", first_section["id"]
  end
end