require_relative 'base'
require_relative 'exceptions'
require 'json'

class GdsApi::GovUkDelivery < GdsApi::Base
  include GdsApi::ExceptionHandling

  def initialize(endpoint_url, options={})
    super(endpoint_url, options.merge({timeout: 10}))
  end

  def subscribe(email, feed_urls)
    data = {email: email, feed_urls: feed_urls}
    url = "#{base_url}/subscriptions"
    post_url(url, data)
  end

  def topic(feed_url, title, description=nil)
    data = {feed_url: feed_url, title: title, description: description}
    url = "#{base_url}/lists"
    post_url(url, data)
  end

  def signup_url(feed_url)
    if response = get_json("#{base_url}/list-url?feed_url=#{CGI.escape(feed_url)}")
      response.list_url
    end
  end

  def notify(feed_urls, subject, body)
    data = {feed_urls: feed_urls, subject: subject, body: body}
    url = "#{base_url}/notifications"
    post_url(url, data)
  end

private
  def base_url
    endpoint
  end

  def post_url(url, data)
    if ! @options[:noop]
      post_json(url, data)
    elsif @options[:noop] && @options[:stdout]
      puts "Would POST #{data.to_json} to #{url}"
    end
  end
end
