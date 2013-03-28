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
    govuk_delivery_create_topic_success('http://example.com/feed', 'Title')
    response = @api.topic("http://example.com/feed", "Title")
    assert response
  end

  it "can subscribe a new email" do
    govuk_delivery_create_subscriber_success('me@example.com', ['http://example.com/feed'])
    response = @api.subscribe('me@example.com', ['http://example.com/feed'])
    assert response
  end

  it "can post a notification" do
    govuk_delivery_create_notification_success(['http://example.com/feed'], 'Test', '<p>Something</p>')
    response = @api.notify(['http://example.com/feed'], 'Test', '<p>Something</p>')
    assert response
  end
end
