require "test_helper"
require "gds_api/content_api"

describe "GdsApi::ContentApi::Response" do

  DummyNetResponse = Struct.new(:body)

  def response_for(net_response)
    website_root = "https://www.gov.uk"
    GdsApi::ContentApi::Response.new(net_response, website_root: website_root)
  end

  it "should map web URLs" do
    body = {
      "web_url" => "https://www.gov.uk/test"
    }.to_json
    assert_equal "/test", response_for(DummyNetResponse.new(body)).web_url
  end

  it "should leave other properties alone" do
    body = {
      "title" => "Title",
      "description" => "Description"
    }.to_json
    response = response_for(DummyNetResponse.new(body))
    assert_equal "Title", response.title
    assert_equal "Description", response.description
  end

  it "should traverse into arrays" do
    body = {
      "other_urls" => [
        { "title" => "Pies", "web_url" => "https://www.gov.uk/pies" },
        { "title" => "Cheese", "web_url" => "https://www.gov.uk/cheese" }
      ]
    }.to_json

    response = response_for(DummyNetResponse.new(body))
    assert_equal "/pies", response.other_urls[0].web_url
    assert_equal "/cheese", response.other_urls[1].web_url
  end

  it "should traverse into hashes" do
    body = {
      "details" => {
        "chirality" => "widdershins",
        "web_url" => "https://www.gov.uk/left"
      }
    }.to_json

    response = response_for(DummyNetResponse.new(body))
    assert_equal "/left", response.details.web_url
  end

  it "should handle nil values" do
    body = {"web_url" => nil}.to_json

    response = response_for(DummyNetResponse.new(body))
    assert_nil response.web_url
  end

  it "should handle query parameters" do
    body = {
      "web_url" => "https://www.gov.uk/thing?does=stuff"
    }.to_json

    response = response_for(DummyNetResponse.new(body))
    assert_equal "/thing?does=stuff", response.web_url
  end

  it "should handle fragments" do
    body = {
      "web_url" => "https://www.gov.uk/thing#part-2"
    }.to_json

    response = response_for(DummyNetResponse.new(body))
    assert_equal "/thing#part-2", response.web_url
  end

  it "should keep URLs from other domains absolute" do
    body = {
      "web_url" => "http://www.example.com/example"
    }.to_json

    response = response_for(DummyNetResponse.new(body))
    assert_equal "http://www.example.com/example", response.web_url
  end
end
