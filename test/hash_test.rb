require 'test_helper'
require 'gds_api/core-ext/hash'

describe Hash do
  it "can deep stringify" do
    hash = { a: "b", c: { d: "e" } }
    assert_equal({"a"=>"b", "c"=>{"d"=>"e"}}, hash.deep_stringify_keys)
  end
end
