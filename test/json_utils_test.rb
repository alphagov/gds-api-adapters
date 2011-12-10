class JsonUtilsTest < MiniTest::Unit::TestCase
  include GdsApi::JsonUtils
  
  # def test_get_returns_nil_on_timeout
  #   
  # end
  
  def test_should_fetch_and_parse_json_into_hash
     url = "http://some.endpoint/some.json"
     stub_request(:get, url).to_return(:body => "{}",:status => 200)
     assert_equal Hash, get_json(url).class
  end

  def test_should_return_nil_if_404_returned_from_endpoint
     url = "http://some.endpoint/some.json"
     stub_request(:get, url).to_return(:body => "{}", :status => 404)
     assert_nil get_json(url)
  end

end