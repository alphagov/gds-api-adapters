require 'test_helper'
require 'gds_api/rummager'
require 'gds_api/test_helpers/rummager'

class RummagerHelpersTest < MiniTest::Unit::TestCase
  include GdsApi::TestHelpers::Rummager

  def test_services_and_info_data_returns_an_adequate_response_object
    response = rummager_has_services_and_info_data_for_organisation

    assert_instance_of GdsApi::Response, response
  end

  def test_no_services_and_info_data_found_for_organisation
    response = rummager_has_no_services_and_info_data_for_organisation

    assert_instance_of GdsApi::Response, response
    assert_equal 0, response.facets.specialist_sectors.total_options
  end
end
