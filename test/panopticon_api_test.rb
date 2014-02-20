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

  def registerable_artefact
    {
      slug: 'foo',
      owning_app: 'my-app',
      kind: 'custom-application',
      name: 'MyFoo',
      description: 'A custom foo of great customness.',
      state: 'live'
    }
  end

  def api
    GdsApi::Panopticon.new(PANOPTICON_ENDPOINT)
  end

  def test_given_a_slug__should_fetch_artefact_from_panopticon
    panopticon_has_metadata(basic_artefact)

    artefact = api.artefact_for_slug(basic_artefact[:slug])
    assert_equal 'An artefact', artefact.name
  end

  def test_given_a_slug_can_fetch_artefact_as_hash
    panopticon_has_metadata(basic_artefact)
    artefact = api.artefact_for_slug(basic_artefact[:slug], :as_hash => true)
    assert_equal basic_artefact[:name], artefact['name']
  end

  def should_fetch_and_parse_JSON_into_hash
    url = "#{PANOPTICON_ENDPOINT}/some.json"
    stub_request(:get, url).to_return(body: {a:1}.to_json)
  
    assert_equal 1, api.get_json(url)['a']
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

  def test_can_delete_an_artefact
    url = "#{PANOPTICON_ENDPOINT}/artefacts/1.json"
    stub_request(:delete, url)
      .with(body: "")
      .to_return(status: 200, body: '{}')

    api.delete_artefact!(1)
  end

  def test_can_use_basic_auth
    credentials = {user: 'fred', password: 'secret'}
    api = GdsApi::Panopticon.new('http://some.url', basic_auth: credentials)
    url = "http://#{credentials[:user]}:#{credentials[:password]}@some.url/artefacts/1.json"
    stub_request(:put, url)
      .to_return(status: 200, body: '{}')

    api.update_artefact(1, basic_artefact)
  end

  def test_can_register_new_artefacts_en_masse
    r = GdsApi::Panopticon::Registerer.new(endpoint_url: PANOPTICON_ENDPOINT, owning_app: 'my-app')
    artefact = registerable_artefact()
    panopticon_has_no_metadata_for('foo')

    stub_request(:put, "#{PANOPTICON_ENDPOINT}/artefacts/foo.json")
      .with(body: artefact.to_json)
      .to_return(body: artefact.merge(id: 1).to_json)

    url = "#{PANOPTICON_ENDPOINT}/artefacts.json"
    stub_request(:post, url)
      .with(body: artefact.to_json)
      .to_return(body: artefact.merge(id: 1).to_json)

    record = OpenStruct.new(artefact.merge(title: artefact[:name]))
    r.register(record)
  end

  def test_can_register_existing_artefacts_en_masse
    artefact = registerable_artefact()
    r = GdsApi::Panopticon::Registerer.new(endpoint_url: PANOPTICON_ENDPOINT, owning_app: 'my-app')

    panopticon_has_metadata(artefact)
    url = "#{PANOPTICON_ENDPOINT}/artefacts/foo.json"
    stub_request(:put, url)
      .with(body: artefact.to_json)
      .to_return(status: 200, body: '{}')

    record = OpenStruct.new(artefact.merge(title: artefact[:name]))
    r.register(record)
  end
end
