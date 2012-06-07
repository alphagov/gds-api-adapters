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

  def test_should_get_licence_details_from_publisher
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

  def test_should_return_empty_array_with_no_licences
    setup_publisher_licences_stubs

    assert_equal [], api.licences_for_ids([123,124])
  end
end
