require 'test_helper'
require 'gds_api/publisher'
require 'gds_api/json_client'
require 'gds_api/test_helpers/publisher'

describe GdsApi::Publisher do
  include GdsApi::TestHelpers::Publisher

  def basic_answer
    {
      "audiences" => [""],
      "slug" => "a-publication",
      "tags" => "",
      "updated_at" => "2011-07-28T11:53:03+00:00",
      "type" => "answer",
      "body" => "Something",
      "title" => "A publication"
    }
  end

  def publication_with_parts
    {
      "audiences" => [""],
      "slug" => "a-publication",
      "tags" => "",
      "updated_at" => "2011-07-28T11:53:03+00:00",
      "type" => "guide",
      "body" => "Something",
      "parts" => [
        {
          "body" => "You may be financially protected",
          "number" => 1,
          "slug" => "introduction",
          "title" => "Introduction"
        },
        {
          "body" => "All companies selling packag",
          "number" => 2,
          "slug" => "if-you-booked-a-package-holiday",
          "title" => "If you booked a package holiday"
        },
        {
          "body" => "##Know your rights when you b",
          "number" => 3,
          "slug" => "if-you-booked-your-trip-independently",
          "title" => "If you booked your trip independently"
        }
      ],
      "title" => "A publication"
    }
  end

  def api
    GdsApi::Publisher.new("test")
  end

  it "should go get resource from publisher app given a slug" do
    publication_exists(basic_answer)
    pub = api.publication_for_slug(basic_answer['slug'])

    assert_equal "Something", pub.body
  end

  it "should optionally accept an edition id" do
    slug = "a-publication"
    publication = %@{"audiences":[""],
      "slug":"#{slug}",
      "tags":"",
      "updated_at":"2011-07-28T11:53:03+00:00",
      "type":"answer",
      "body":"Something",
      "title":"A publication"}@
    stub_request(:get, "#{PUBLISHER_ENDPOINT}/publications/#{slug}.json?edition=678").to_return(
      :body => publication,:status=>200)

    pub = api.publication_for_slug(slug,{:edition => 678})
  end

  it "should construct correct url for a slug" do
    assert_equal "#{PUBLISHER_ENDPOINT}/publications/slug.json", api.url_for_slug("slug")
  end

  it "should deserialise parts into whole objects" do
    publication_exists(publication_with_parts)
    pub = api.publication_for_slug(publication_with_parts['slug'])
    assert_equal 3, pub.parts.size
    assert_equal "introduction", pub.parts.first.slug
  end

  it "should have part specific methods for a publication with parts" do
    publication_exists(publication_with_parts)
    pub = api.publication_for_slug(publication_with_parts['slug'])
    assert_equal pub.part_index("introduction"),0
  end

  it "should deserialise updated at as a time" do
    publication_exists(publication_with_parts)
    pub = api.publication_for_slug(publication_with_parts['slug'])
    assert_equal Time, pub.updated_at.class
  end

  it "should be able to retrieve local transaction details" do
    stub_request(:post, "#{PUBLISHER_ENDPOINT}/local_transactions/fake-transaction/verify_snac.json").
      with(:body => "{\"snac_codes\":[12345]}", :headers => GdsApi::JsonClient::REQUEST_HEADERS).
      to_return(:status => 200, :body => '{"snac": "12345"}', :headers => {})
    assert_equal '12345', api.council_for_slug('fake-transaction', [12345])
  end

  describe "getting licence details from publisher" do
    it "should get licence details from publisher" do
      setup_publisher_licences_stubs

      publisher_has_licence :licence_identifier => "1234", :title => 'Test Licence 1', :slug => 'test-licence-1',
        :licence_short_description => 'A short description'
      publisher_has_licence :licence_identifier => "1235", :title => 'Test Licence 2', :slug => 'test-licence-2',
        :licence_short_description => 'A short description'
      publisher_has_licence :licence_identifier => "AB1234", :title => 'Test Licence 3', :slug => 'test-licence-3',
        :licence_short_description => 'A short description'

      results = api.licences_for_ids([1234, 'AB1234', 'something'])
      assert_equal 2, results.size
      assert_equal ['1234', 'AB1234'], results.map(&:licence_identifier)
      assert_equal ['Test Licence 1', 'Test Licence 3'], results.map(&:title).sort
      assert_equal ['test-licence-1', 'test-licence-3'], results.map(&:slug).sort
      assert_equal 'A short description', results[0].licence_short_description
      assert_equal 'A short description', results[1].licence_short_description
    end

    it "should return empty array with no licences" do
      setup_publisher_licences_stubs

      assert_equal [], api.licences_for_ids([123,124])
    end

    it "should return nil if publisher returns an error" do
      stub_request(:get, %r[\A#{PUBLISHER_ENDPOINT}/licences]).
        to_return(:status => [503, "Service temporarily unabailable"])

      assert_equal nil, api.licences_for_ids([123,124])
    end
  end
end
