require 'test_helper'
require 'gds_api/publisher'

class GdsApi::PublisherTest < MiniTest::Unit::TestCase
  EXPECTED_ENDPOINT = "http://publisher.test.alphagov.co.uk"
  
  def api
    GdsApi::Publisher.new("test")
  end
  
  def test_given_a_slug__should_go_get_resource_from_publisher_app
    slug = "a-publication"
    publication = %@{"audiences":[""],
      "slug":"#{slug}",
      "tags":"",
      "updated_at":"2011-07-28T11:53:03+00:00",
      "type":"answer",
      "body":"Something",
      "title":"A publication"}@
    stub_request(:get, "#{EXPECTED_ENDPOINT}/publications/#{slug}.json").to_return(
      :body => publication,:status=>200)     
    
    pub = api.publication_for_slug(slug)

    assert_equal "Something",pub.body
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
    stub_request(:get, "#{EXPECTED_ENDPOINT}/publications/#{slug}.json?edition=678").to_return(
      :body => publication,:status=>200)     
    
    pub = api.publication_for_slug(slug,{:edition => 678})
  end

  def test_should_fetch_and_parse_json_into_hash
     url = "#{EXPECTED_ENDPOINT}/some.json"
     stub_request(:get, url).to_return(
      :body => "{}",:status=>200) 
     assert_equal Hash,api.get_json(url).class
  end

  def test_should_return_nil_if_404_returned_from_endpoint
     url = "#{EXPECTED_ENDPOINT}/some.json"
     stub_request(:get, url).to_return(
      :body => "{}",:status=>404) 
     assert_nil api.get_json(url)
  end

  def test_should_construct_correct_url_for_a_slug
    assert_equal "#{EXPECTED_ENDPOINT}/publications/slug.json", api.url_for_slug("slug")
  end

  def publication_with_parts(slug)
    publication = %@{"audiences":[""],
      "slug":"#{slug}",
      "tags":"",
      "updated_at":"2011-07-28T11:53:03+00:00",
      "type":"guide",
      "body":"Something",
      "parts" : [
      {
         "body" : "You may be financially protected",
         "number" : 1,
         "slug" : "introduction",
         "title" : "Introduction"
      },
      {
         "body" : "All companies selling packag",
         "number" : 2,
         "slug" : "if-you-booked-a-package-holiday",
         "title" : "If you booked a package holiday"
      },
      {
         "body" : "##Know your rights when you b",
         "number" : 3,
         "slug" : "if-you-booked-your-trip-independently",
         "title" : "If you booked your trip independently"
      }],
      "title":"A publication"}@

  end

  def test_parts_should_be_deserialised_into_whole_objects
    slug = "a-publication"
    publication = publication_with_parts(slug)
    stub_request(:get, "#{EXPECTED_ENDPOINT}/publications/#{slug}.json").to_return(
      :body => publication,:status=>200)     
    
    pub = api.publication_for_slug(slug)
    assert_equal 3, pub.parts.size
    assert_equal "introduction", pub.parts.first.slug
  end

  def test_a_publication_with_parts_should_have_part_specific_methods
    slug = "a-publication"
    publication = publication_with_parts(slug)
    stub_request(:get, "#{EXPECTED_ENDPOINT}/publications/#{slug}.json").to_return(
      :body => publication,:status=>200)     
    
    pub = api.publication_for_slug(slug)
    assert_equal pub.part_index("introduction"),0
  end

  def test_updated_at_should_be_a_time_on_deserialisation
    slug = "a-publication"
    publication = publication_with_parts(slug)
    stub_request(:get, "#{EXPECTED_ENDPOINT}/publications/#{slug}.json").to_return(
      :body => publication,:status=>200)     
    
    pub = api.publication_for_slug(slug)
    assert_equal Time, pub.updated_at.class
  end

end
