require 'test_helper'
require 'gds_api/content_api'
require 'gds_api/test_helpers/content_api'

class ContentApiApiTest < MiniTest::Unit::TestCase
  include GdsApi::TestHelpers::ContentApi

  def basic_artefact
    {
      name: 'An artefact',
      slug: 'a-basic-artefact'
    }
  end

  def artefact_with_contact
    {
      name: 'An artefact',
      slug: 'an-artefact-with-contact',
      contact: {
        name: 'Department for Environment, Food and Rural Affairs (Defra)',
        email_address: 'helpline@defra.gsi.gov.uk'
      }
    }
  end

  def api
    GdsApi::ContentApi.new('test')
  end

  def test_given_a_slug__should_fetch_artefact_from_panopticon
    content_api_has_metadata(basic_artefact)

    artefact = api.artefact_for_slug(basic_artefact[:slug])
    assert_equal 'An artefact', artefact.name
  end

  def test_given_a_slug_can_fetch_artefact_as_hash
    content_api_has_metadata(basic_artefact)
    artefact = api.artefact_for_slug(basic_artefact[:slug], :as_hash => true)
    assert_equal basic_artefact[:name], artefact['name']
  end

  def should_fetch_and_parse_JSON_into_hash
    url = "#{CONTENT_API_ENDPOINT}/some.json"
    stub_request(:get, url).to_return(body: {a:1}.to_json)
  
    assert_equal 1, api.get_json(url)['a']
  end

  def test_should_return_nil_if_404_returned_from_endpoint
    url = "#{CONTENT_API_ENDPOINT}/some.json"
    stub_request(:get, url).to_return(status: Rack::Utils.status_code(:not_found))

    assert_nil api.get_json(url)
  end

  def test_should_construct_correct_url_for_a_slug
    assert_equal "#{CONTENT_API_ENDPOINT}/artefacts/slug.json", api.url_for_slug('slug')
  end

  def test_contacts_should_be_deserialised_into_whole_objects
    content_api_has_metadata(artefact_with_contact)

    artefact = api.artefact_for_slug(artefact_with_contact[:slug])
    assert_equal 'Department for Environment, Food and Rural Affairs (Defra)', artefact.contact.name
    assert_equal 'helpline@defra.gsi.gov.uk', artefact.contact.email_address
  end

  def test_can_use_basic_auth
    credentials = {user: 'fred', password: 'secret'}
    api = GdsApi::ContentApi.new('test', endpoint_url: 'http://some.url', basic_auth: credentials)
    url = "http://#{credentials[:user]}:#{credentials[:password]}@some.url/artefacts/1.json"
    stub_request(:get, url)
      .to_return(status: 200, body: '{}')

    api.artefact_for_slug("1")
  end
end
