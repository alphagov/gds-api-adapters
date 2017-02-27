require 'test_helper'
require 'gds_api/gov_uk_delivery'
require 'gds_api/test_helpers/gov_uk_delivery'

describe GdsApi::GovUkDelivery do
  include GdsApi::TestHelpers::GovUkDelivery

  before do
    @base_api_url = Plek.current.find("govuk-delivery")
    @api = GdsApi::GovUkDelivery.new(@base_api_url)
  end

  it "can create a topic" do
    expected_payload = { feed_url: 'http://example.com/feed', title: 'Title', description: nil }
    stub = stub_gov_uk_delivery_post_request('lists', expected_payload).to_return(created_response_hash)

    assert @api.topic("http://example.com/feed", "Title")
    assert_requested stub
  end

  it "can subscribe a new email" do
    expected_payload = { email: 'me@example.com', feed_urls: ['http://example.com/feed'] }
    stub = stub_gov_uk_delivery_post_request('subscriptions', expected_payload).to_return(created_response_hash)

    assert @api.subscribe('me@example.com', ['http://example.com/feed'])
    assert_requested stub
  end

  it "can post a notification" do
    expected_payload = { feed_urls: ['http://example.com/feed'], subject: 'Test', body: '<p>Something</p>', logging_params: { content_id: 'aaaaaa-11111' } }
    stub = stub_gov_uk_delivery_post_request('notifications', expected_payload).to_return(created_response_hash)

    assert @api.notify(['http://example.com/feed'], 'Test', '<p>Something</p>', content_id: 'aaaaaa-11111')
    assert_requested stub
  end

  it "can get a subscription URL" do
    expected_payload = { feed_url: 'http://example.com/feed' }
    stub = stub_gov_uk_delivery_get_request('list-url', expected_payload).to_return(created_response_json_hash(list_url: 'thing'))

    assert @api.signup_url('http://example.com/feed')
    assert_requested stub
  end

  it "raises if the API 404s" do
    expected_payload = { feed_url: 'http://example.com/feed' }
    stub_gov_uk_delivery_get_request('list-url', expected_payload).to_return(not_found_hash)

    assert_raises(GdsApi::HTTPNotFound) do
      @api.signup_url('http://example.com/feed')
    end
  end

  private

  def created_response_hash
    { body: '', status: 201 }
  end

  def not_found_hash
    { body: '', status: 404 }
  end

  def created_response_json_hash(data)
    { body: data.to_json, status: 201 }
  end
end
