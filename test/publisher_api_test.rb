require 'test_helper'
require 'gds_api/publisher'
require 'gds_api/json_client'
require 'gds_api/test_helpers/publisher'

describe GdsApi::Publisher do
  include GdsApi::TestHelpers::Publisher
  PUBLISHER_ENDPOINT = GdsApi::TestHelpers::Publisher::PUBLISHER_ENDPOINT

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
    GdsApi::Publisher.new(PUBLISHER_ENDPOINT)
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
      with(:body => "{\"snac_codes\":[12345]}", :headers => GdsApi::JsonClient::DEFAULT_REQUEST_HEADERS).
      to_return(:status => 200, :body => '{"snac": "12345"}', :headers => {})
    assert_equal '12345', api.council_for_slug('fake-transaction', [12345])
  end
end
