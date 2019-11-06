require "test_helper"
require "gds_api/search"
require "gds_api/test_helpers/search"

class SearchHelpersTest < Minitest::Test
  include GdsApi::TestHelpers::Search

  def test_services_and_info_data_returns_an_adequate_response_object
    response = stub_search_has_services_and_info_data_for_organisation

    assert_instance_of GdsApi::Response, response
  end

  def test_no_services_and_info_data_found_for_organisation
    response = stub_search_has_no_services_and_info_data_for_organisation

    assert_instance_of GdsApi::Response, response
    assert_equal 0, response["facets"]["specialist_sectors"]["total_options"]
  end
end
