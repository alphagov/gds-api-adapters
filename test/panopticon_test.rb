require 'test_helper'
require 'gds_api/panopticon'
require 'gds_api/test_helpers/panopticon'

describe GdsApi::Panopticon do
  include GdsApi::TestHelpers::Panopticon

  let(:base_api_endpoint) { GdsApi::TestHelpers::Panopticon::PANOPTICON_ENDPOINT }
  let(:api) { GdsApi::Panopticon.new(base_api_endpoint) }

  let(:basic_artefact) {
    {
      name: 'An artefact',
      slug: 'a-basic-artefact'
    }
  }
  let(:artefact_with_contact) {
    {
      name: 'An artefact',
      slug: 'an-artefact-with-contact',
      contact: {
        name: 'Department for Environment, Food and Rural Affairs (Defra)',
        email_address: 'helpline@defra.gsi.gov.uk'
      }
    }
  }
  let(:registerable_artefact) {
    {
      slug: 'foo',
      owning_app: 'my-app',
      kind: 'custom-application',
      name: 'MyFoo',
      description: 'A custom foo of great customness.',
      state: 'live'
    }
  }

  it 'fetches an artefact given a slug' do
    panopticon_has_metadata(basic_artefact)

    artefact = api.artefact_for_slug(basic_artefact[:slug])
    assert_equal 'An artefact', artefact.name
  end

  it 'fetches an artefact as a hash given a slug' do
    panopticon_has_metadata(basic_artefact)
    artefact = api.artefact_for_slug(basic_artefact[:slug], :as_hash => true)
    assert_equal basic_artefact[:name], artefact['name']
  end

  it 'fetches and parses JSON into a hash' do
    url = "#{base_api_endpoint}/some.json"
    stub_request(:get, url).to_return(body: {a:1}.to_json)

    assert_equal 1, api.get_json(url)['a']
  end

  it 'returns nil if the endpoint returns 404' do
    url = "#{base_api_endpoint}/some.json"
    stub_request(:get, url).to_return(status: Rack::Utils.status_code(:not_found))

    assert_nil api.get_json(url)
  end

  it 'constructs the correct URL for a slug' do
    assert_equal "#{base_api_endpoint}/artefacts/slug.json", api.url_for_slug('slug')
  end

  it 'deserialises contacts into whole objects' do
    panopticon_has_metadata(artefact_with_contact)

    artefact = api.artefact_for_slug(artefact_with_contact[:slug])
    assert_equal 'Department for Environment, Food and Rural Affairs (Defra)', artefact.contact.name
    assert_equal 'helpline@defra.gsi.gov.uk', artefact.contact.email_address
  end

  it 'creates a new artefact' do
    url = "#{base_api_endpoint}/artefacts.json"
    stub_request(:post, url)
      .with(body: basic_artefact.to_json)
      .to_return(body: basic_artefact.merge(id: 1).to_json)

    api.create_artefact(basic_artefact)
  end

  it 'updates an existing artefact' do
    url = "#{base_api_endpoint}/artefacts/1.json"
    stub_request(:put, url)
      .with(body: basic_artefact.to_json)
      .to_return(status: 200, body: '{}')

    api.update_artefact(1, basic_artefact)
  end

  it 'deletes an artefact' do
    url = "#{base_api_endpoint}/artefacts/1.json"
    stub_request(:delete, url)
      .with(body: "")
      .to_return(status: 200, body: '{}')

    api.delete_artefact!(1)
  end

  it 'uses basic auth' do
    credentials = {user: 'fred', password: 'secret'}
    api = GdsApi::Panopticon.new('http://some.url', basic_auth: credentials)
    url = "http://#{credentials[:user]}:#{credentials[:password]}@some.url/artefacts/1.json"
    stub_request(:put, url)
      .to_return(status: 200, body: '{}')

    api.update_artefact(1, basic_artefact)
  end

  it 'registers new artefacts en masse' do
    r = GdsApi::Panopticon::Registerer.new(endpoint_url: base_api_endpoint, owning_app: 'my-app')
    artefact = registerable_artefact()
    panopticon_has_no_metadata_for('foo')

    stub_request(:put, "#{base_api_endpoint}/artefacts/foo.json")
      .with(body: artefact.to_json)
      .to_return(body: artefact.merge(id: 1).to_json)

    url = "#{base_api_endpoint}/artefacts.json"
    stub_request(:post, url)
      .with(body: artefact.to_json)
      .to_return(body: artefact.merge(id: 1).to_json)

    record = OpenStruct.new(artefact.merge(title: artefact[:name]))
    r.register(record)
  end

  it 'registers existing artefacts en masse' do
    artefact = registerable_artefact()
    r = GdsApi::Panopticon::Registerer.new(endpoint_url: base_api_endpoint, owning_app: 'my-app')

    panopticon_has_metadata(artefact)
    url = "#{base_api_endpoint}/artefacts/foo.json"
    stub_request(:put, url)
      .with(body: artefact.to_json)
      .to_return(status: 200, body: '{}')

    record = OpenStruct.new(artefact.merge(title: artefact[:name]))
    r.register(record)
  end
end
