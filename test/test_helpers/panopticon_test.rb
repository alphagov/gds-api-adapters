require 'test_helper'
require 'gds_api/panopticon'
require 'gds_api/test_helpers/panopticon'

describe GdsApi::TestHelpers::Panopticon do
  include GdsApi::TestHelpers::Panopticon

  def assert_stub_exists(*args)
    expected_signature = WebMock::RequestSignature.new(*args)

    assert(
      WebMock::StubRegistry.instance.registered_request?(expected_signature),
      "Stub is not registered:\n\t#{expected_signature.to_s}"
    )
  end

  let(:base_api_endpoint) { GdsApi::TestHelpers::Panopticon::PANOPTICON_ENDPOINT }

  it 'stubs the tag creation request' do
    atts = { tag_id: 'foo' }
    stub_panopticon_tag_creation(atts)

    assert_stub_exists(:post, "#{base_api_endpoint}/tags.json", body: atts.to_json)
  end

  it 'stubs the tag update request' do
    atts = { title: 'Foo' }
    stub_panopticon_tag_update('section', 'foo/bar', atts)

    assert_stub_exists(:put,
      "#{base_api_endpoint}/tags/section/foo/bar.json",
      body: atts.to_json
    )
  end

  it 'stubs the tag publish request' do
    stub_panopticon_tag_publish('section', 'foo/bar')

    assert_stub_exists(:post,
      "#{base_api_endpoint}/tags/section/foo/bar/publish.json",
      body: {}.to_json
    )
  end
end
