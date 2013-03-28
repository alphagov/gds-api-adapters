require_relative 'base'
require_relative 'exceptions'

class GdsApi::GovUkDelivery < GdsApi::Base
  include GdsApi::ExceptionHandling

  def subscribe(email, feed_urls)
    post_json("#{base_url}/subscriptions", {email: email, feed_urls: feed_urls})
  end

  def topic(feed_url, title, description=nil)
    post_json("#{base_url}/lists", {feed_url: feed_url, title: title, description: description})
  end

  def notify(feed_urls, subject, body)
    # TODO: should this be multipart?
    post_json("#{base_url}/notifications", {feed_urls: feed_urls, subject: subject, body: body})
  end

private
  def base_url
    endpoint
  end
end
