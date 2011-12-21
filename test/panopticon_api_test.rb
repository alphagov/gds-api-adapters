require 'test_helper'
require 'gds_api/panopticon'
require 'gds_api/test_helpers/panopticon'

class PanopticonApiTest < MiniTest::Unit::TestCase
  include GdsApi::TestHelpers::Panopticon

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
    GdsApi::Panopticon.new('test')
  end

  def test_given_a_slug__should_fetch_artefact_from_panopticon
    panopticon_has_metadata(basic_artefact)
  
    artefact = api.artefact_for_slug(basic_artefact[:slug])
    assert_equal 'An artefact', artefact.name
  end
  
  def test_given_a_slug_can_fetch_artefact_as_hash
    panopticon_has_metadata(basic_artefact)
    artefact = api.artefact_for_slug(basic_artefact[:slug], :as_hash => true)
    assert artefact.is_a?(Hash)
  end
  
  def should_fetch_and_parse_JSON_into_hash
    url = "#{PANOPTICON_ENDPOINT}/some.json"
    stub_request(:get, url).to_return(body: {}.to_json)
  
    assert_equal Hash, api.get_json(url).class
  end
  
  def test_should_return_nil_if_404_returned_from_endpoint
    url = "#{PANOPTICON_ENDPOINT}/some.json"
    stub_request(:get, url).to_return(status: Rack::Utils.status_code(:not_found))
  
    assert_nil api.get_json(url)
  end
  
  def test_should_construct_correct_url_for_a_slug
    assert_equal "#{PANOPTICON_ENDPOINT}/artefacts/slug.json", api.url_for_slug('slug')
  end
  
  def test_contacts_should_be_deserialised_into_whole_objects
    panopticon_has_metadata(artefact_with_contact)

    artefact = api.artefact_for_slug(artefact_with_contact[:slug])
    assert_equal 'Department for Environment, Food and Rural Affairs (Defra)', artefact.contact.name
    assert_equal 'helpline@defra.gsi.gov.uk', artefact.contact.email_address
  end
  
  def test_can_create_a_new_artefact
    url = "#{PANOPTICON_ENDPOINT}/artefacts.json"
    stub_request(:post, url)
      .with(body: basic_artefact.to_json)
      .to_return(body: basic_artefact.merge(id: 1).to_json)
    
    api.create_artefact(basic_artefact)
  end
  
  def test_can_update_existing_artefact
    url = "#{PANOPTICON_ENDPOINT}/artefacts/1.json"
    stub_request(:put, url)
      .with(body: basic_artefact.to_json)
      .to_return(status: 200, body: '{}')
    
    api.update_artefact(1, basic_artefact)
  end
end
