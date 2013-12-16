require 'test_helper'
require 'gds_api/business_support_api'
require 'gds_api/test_helpers/business_support_api'

describe GdsApi::BusinessSupportApi do
  include GdsApi::TestHelpers::BusinessSupportApi

  before do
    @base_api_url = Plek.current.find("business-support-api")
    @api = GdsApi::BusinessSupportApi.new(@base_api_url)
    setup_business_support_api_schemes_stubs
  end

  describe "searching for schemes" do
    it "should return all schemes when called with no facets" do
      business_support_api_has_schemes([:scheme1, :scheme2, :scheme3])
      response = @api.schemes
      assert_equal ["scheme1", "scheme2", "scheme3"], response['results']
    end
    it "should return schemes for applicable facets"  do
      business_support_api_has_scheme(:scottish_manufacturing, {locations: 'scotland', sectors: 'manufacturing', support_types: 'grant,loan'})
      response = @api.schemes({locations: 'scotland', sectors: 'manufacturing', support_types: 'grant,loan'})
      assert_equal ["scottish_manufacturing"], response["results"]
    end
    it "should return an empty result when facets are not applicable" do
      business_support_api_has_scheme(:super_secret, {locations: 'the moon', sectors: 'espionage'})
      response = @api.schemes({locations: 'earth', sectors: 'espionage'})
      assert_empty response["results"]
    end
  end

  describe "finding a scheme by slug" do
    it "should give the scheme details" do
      business_support_api_has_a_scheme('superbiz-wunderfundz', {
        :title => 'Superbiz wunderfundz',
        :short_description => 'Wunderfundz for your superbiz',
        :body => 'Do you run or work for a Superbiz? Well we have the Wunderfundz.'})
      response = @api.scheme('superbiz-wunderfundz')
      assert_equal 'business_support', response['format']
      assert_equal 'Superbiz wunderfundz', response['title']
      assert_equal 'Wunderfundz for your superbiz', response['details']['short_description']
      assert_equal 'Do you run or work for a Superbiz? Well we have the Wunderfundz.', response['details']['body']
    end
  end
end
