require 'test_helper'
require 'gds_api/finder_api'

describe GdsApi::FinderApi do
  before do
    @base_api_url = Plek.current.find('finder-api')
    @api = GdsApi::FinderApi.new(@base_api_url, schema_factory: schema_factory)
  end

  let(:schema) { Object.new }
  let(:schema_factory) {
    ->(schema_as_a_hash) { schema }
  }

  describe "get_documents" do
    it "should return all documents" do
      documents_hash = {
        'documents' => [
          {
            'title' => 'A document',
            'date' => '2014-01-24 00:00:00 +0000',
            'case_type' => 'market-investigations'
          },
          {
            'title' => 'Blah blah',
            'date' => '2014-01-25 00:00:00 +0000',
            'case_type' => 'merger-inquiries'
          }
        ]
      }

      req = WebMock.stub_request(:get, "#{@base_api_url}/finders/some-finder-slug/documents.json").
        to_return(:body => documents_hash.to_json,
                  :headers => {"Content-type" => "application/json"})

      response = @api.get_documents("some-finder-slug")
      assert_equal 200, response.code
      assert_equal documents_hash, response.to_hash

      assert_requested(req)
    end

    it "should forward query parameters" do
      documents_hash = {
        'documents' => [
          {
            'title' => 'A document',
            'date' => '2014-01-24 00:00:00 +0000',
            'case_type' => 'market-investigations'
          }
        ]
      }

      req = WebMock.stub_request(:get, "#{@base_api_url}/finders/some-finder-slug/documents.json").
        with(query: {case_type: 'market-investigations'}).
        to_return(:body => documents_hash.to_json,
                  :headers => {"Content-type" => "application/json"})

      response = @api.get_documents("some-finder-slug", case_type: 'market-investigations')
      assert_equal 200, response.code
      assert_equal documents_hash, response.to_hash

      assert_requested(req)
    end
  end

  describe "get_schema" do
    let(:schema_factory) {
      Minitest::Mock.new
        .expect(:call, schema, [schema_hash])
    }

    let(:schema_hash) {
      {'it is' => 'a schema'}
    }

    let(:schema_json) {
      schema_hash.to_json
    }

    let(:schema_url) {
      "#{@base_api_url}/finders/cma-cases/schema.json"
    }

    it "requests the finder's schema" do
      req = WebMock.stub_request(:get, schema_url).
        to_return(:body => schema_json,
                  :headers => {"Content-type" => "application/json"})

      response = @api.get_schema("cma-cases")

      assert_requested(req)
    end

    it "constructs and returns a schema object" do
      WebMock.stub_request(:get, schema_url)
        .to_return(
          :body => schema_json,
          :headers => {"Content-type" => "application/json"},
        )

      returned_schema = @api.get_schema("cma-cases")

      assert_equal schema, returned_schema
      schema_factory.verify
    end

    it "should forward query parameters" do
      req = WebMock.stub_request(:get, "#{@base_api_url}/finders/some-finder-slug/schema.json").
        with(query: {locale: 'fr-FR'}).
        to_return(:body => schema_json,
                  :headers => {"Content-type" => "application/json"})

      response = @api.get_schema("some-finder-slug", locale: 'fr-FR')

      assert_requested(req)
    end
  end
end
