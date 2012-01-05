require 'test_helper'
require 'gds_api/publisher'
require 'gds_api/json_client'
require 'gds_api/test_helpers/publisher'

class GdsApi::PublisherTest < MiniTest::Unit::TestCase
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

  def test_given_a_slug_should_go_get_resource_from_publisher_app
    publication_exists(basic_answer)
    pub = api.publication_for_slug(basic_answer['slug'])

    assert_equal "Something", pub.body
  end

  def test_should_optionally_accept_an_edition_id
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

  def test_should_construct_correct_url_for_a_slug
    assert_equal "#{PUBLISHER_ENDPOINT}/publications/slug.json", api.url_for_slug("slug")
  end

  def test_parts_should_be_deserialised_into_whole_objects
    publication_exists(publication_with_parts)
    pub = api.publication_for_slug(publication_with_parts['slug'])
    assert_equal 3, pub.parts.size
    assert_equal "introduction", pub.parts.first.slug
  end

  def test_a_publication_with_parts_should_have_part_specific_methods
    publication_exists(publication_with_parts)
    pub = api.publication_for_slug(publication_with_parts['slug'])
    assert_equal pub.part_index("introduction"),0
  end

  def test_updated_at_should_be_a_time_on_deserialisation
    publication_exists(publication_with_parts)
    pub = api.publication_for_slug(publication_with_parts['slug'])
    assert_equal Time, pub.updated_at.class
  end

  def test_should_be_able_to_retrieve_local_transaction_details
    stub_request(:post, "#{PUBLISHER_ENDPOINT}/local_transactions/fake-transaction/verify_snac.json").
      with(:body => "{\"snac_codes\":[12345]}", :headers => GdsApi::JsonClient::REQUEST_HEADERS).
      to_return(:status => 200, :body => '{"snac": "12345"}', :headers => {})
    assert_equal '12345', api.council_for_slug('fake-transaction', [12345])
  end

end
