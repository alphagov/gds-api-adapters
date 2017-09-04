require 'test_helper'

class GdsApiBaseTest < Minitest::Test
  def test_fingerprints_per_exception_type
    exception = GdsApi::HTTPBadGateway.new(200)

    assert_equal ["GdsApi::HTTPBadGateway"], exception.raven_context[:fingerprint]
  end
end
