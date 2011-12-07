require 'test_helper'
require 'gds_api/panopticon'

class PanopticonApiTest < MiniTest::Unit::TestCase
  EXPECTED_ENDPOINT = 'http://panopticon.test.alphagov.co.uk'

  def api
    GdsApi::Panopticon.new('test')
  end

  def test_given_a_slug__should_fetch_artefact_from_panopticon
    slug = 'an-artefact'
    artefact_json = { name: 'An artefact' }.to_json
    stub_request(:get, "#{EXPECTED_ENDPOINT}/artefacts/#{slug}.json").to_return(body: artefact_json)

    artefact = api.artefact_for_slug(slug)
    assert_equal 'An artefact', artefact.name
  end

  def test_given_a_slug_can_fetch_artefact_as_hash
    slug = 'an-artefact'
    artefact_json = { name: 'An artefact' }.to_json
    stub_request(:get, "#{EXPECTED_ENDPOINT}/artefacts/#{slug}.json").to_return(body: artefact_json)

    artefact = api.artefact_for_slug(slug, :as_hash => true)
    assert artefact.is_a?(Hash)
  end

  def should_fetch_and_parse_JSON_into_hash
    url = "#{EXPECTED_ENDPOINT}/some.json"
    stub_request(:get, url).to_return(body: {}.to_json)

    assert_equal Hash, api.get_json(url).class
  end

  def test_should_return_nil_if_404_returned_from_EXPECTED_ENDPOINT
    url = "#{EXPECTED_ENDPOINT}/some.json"
    stub_request(:get, url).to_return(status: Rack::Utils.status_code(:not_found))

    assert_nil api.get_json(url)
  end

  def test_should_construct_correct_url_for_a_slug
    assert_equal "#{EXPECTED_ENDPOINT}/artefacts/slug.json", api.url_for_slug('slug')
  end

  def artefact_with_contact_json
    {
      name: 'An artefact',
      slug: 'an-artefact',
      contact: {
        name: 'Department for Environment, Food and Rural Affairs (Defra)',
        email_address: 'helpline@defra.gsi.gov.uk'
      }
    }.to_json
  end

  def test_contacts_should_be_deserialised_into_whole_objects
    slug = 'an-artefact'
    artefact_json = artefact_with_contact_json
    stub_request(:get, "#{EXPECTED_ENDPOINT}/artefacts/#{slug}.json").to_return(body: artefact_json)

    artefact = api.artefact_for_slug(slug)
    assert_equal 'Department for Environment, Food and Rural Affairs (Defra)', artefact.contact.name
    assert_equal 'helpline@defra.gsi.gov.uk', artefact.contact.email_address
  end
end
