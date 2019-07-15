require_relative 'test_helper'
require 'gds_api/whitehall_admin'
require 'gds_api/test_helpers/whitehall_admin'

describe GdsApi::WhitehallAdmin do
  include GdsApi::TestHelpers::WhitehallAdmin

  before do
    @base_api_url = GdsApi::TestHelpers::WhitehallAdmin::WHITEHALL_ADMIN_ENDPOINT
    @api = GdsApi::WhitehallAdmin.new(@base_api_url)
  end

  describe "fetching an array of document_ids" do
    it "calls whitehall admins export-data endpoint" do
      content_ids = %w(
        "08122b3d-sdd4c-43d9-aa85-32c4ase984SD"
        "Ab69AAd-asd4c-43d9-aASD5-32c465e198DS"
        "bdsad92sdd-2sd4c-43d9-aa85-32casd4asd"
        "s92b3d-2dsc-4sss3d9-aa85-asdasd5e19as"
      )

      params = {
        lead_organisation_content_id: "08122b3dsadasd-asdasd-ASDadsas-asda",
        document_supertype: "NewsArticle",
        document_type: "news_story"
      }

      stub_whitehall_admin_export_data_has_content_ids(params, content_ids)

      response = @api.export_data(params)
      assert_equal(content_ids, response.body)
    end
  end
end
