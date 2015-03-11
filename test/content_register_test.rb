require 'test_helper'
require 'gds_api/content_register'
require 'gds_api/test_helpers/content_register'

describe GdsApi::ContentRegister do
  include GdsApi::TestHelpers::ContentRegister

  before do
    @api_adapter = GdsApi::ContentRegister.new(Plek.find("content-register"))
  end

  describe "#put_entry method" do
    it "creates an entry in the content register" do
      content_id = SecureRandom.uuid
      entry = {
        "format" => 'organisation',
        "title" => 'Organisation',
        "base_path" => "/government/organisations/organisation"
      }

      stub_content_register_put_entry(content_id, entry)

      response = @api_adapter.put_entry(content_id, entry)
      assert_equal 201, response.code
    end
  end
end
