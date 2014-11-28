require 'test_helper'
require 'gds_api/whitehall_admin_api'

describe GdsApi::WhitehallAdminApi do

  before do
    @api = GdsApi::WhitehallAdminApi.new("http://whitehall-admin.example.com")
  end

  describe "#reindex_specialist_sector_editions(slug)" do
    it "posts to the reindex URL" do
      @api.expects(:post_json!)
        .with("http://whitehall-admin.example.com/government/admin/api/reindex-specialist-sector-editions/oil-and-gas/licensing")

      @api.reindex_specialist_sector_editions("oil-and-gas/licensing")
    end
  end
end
