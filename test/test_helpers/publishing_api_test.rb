require 'test_helper'
require 'gds_api/publishing_api'
require 'gds_api/test_helpers/publishing_api'

describe GdsApi::TestHelpers::PublishingApi do
  include GdsApi::TestHelpers::PublishingApi
  let(:base_api_url) { Plek.current.find("publishing-api") }
  let(:publishing_api) { GdsApi::PublishingApi.new(base_api_url) }

  describe "#assert_publishing_api_put_item" do
    before { stub_default_publishing_api_put }
    let(:base_path) { "/example" }

    it "matches a put request with any empty attributes by default" do
      publishing_api.put_content_item(base_path, {})
      assert_publishing_api_put_item(base_path)
    end

    it "matches a put request with any arbitrary attributes by default" do
      random_attributes = Hash[10.times.map {|n| [Random.rand * 1_000_000_000_000, Random.rand * 1_000_000_000_000]}]
      publishing_api.put_content_item(base_path, random_attributes)
      assert_publishing_api_put_item(base_path)
    end

    it "if attributes are specified, matches a request with at least those attributes" do
      publishing_api.put_content_item(base_path, {"required_attribute" => 1, "extra_attrbibute" => 1})
      assert_publishing_api_put_item(base_path, {"required_attribute" => 1})
    end

    it "matches using a custom request matcher" do
      publishing_api.put_content_item(base_path, {})
      matcher_was_called = false
      matcher = ->(request) { matcher_was_called = true; true }
      assert_publishing_api_put_item(base_path, matcher)
      assert matcher_was_called, "matcher should have been called"
    end
  end

  describe '#request_json_matching predicate' do
    describe "nested required attribute" do
      let(:matcher) { request_json_matching({"a" => {"b" => 1}}) }

      it "matches a body with exact same nested hash strucure" do
        assert matcher.call(stub("request", body: '{"a": {"b": 1}}'))
      end

      it "matches a body with exact same nested hash strucure and an extra attribute at the top level" do
        assert matcher.call(stub("request", body: '{"a": {"b": 1}, "c": 3}'))
      end

      it "does not match a body where the inner hash has the required attribute and an extra one" do
        refute matcher.call(stub("request", body: '{"a": {"b": 1, "c": 2}}'))
      end

      it "does not match a body where the inner hash has the required attribute with the wrong value" do
        refute matcher.call(stub("request", body: '{"a": {"b": 0}}'))
      end

      it "does not match a body where the inner hash lacks the required attribute" do
        refute matcher.call(stub("request", body: '{"a": {"c": 1}}'))
      end
    end

    describe "hash to match uses symbol keys" do
      let(:matcher) { request_json_matching({a: 1}) }

      it "matches a json body" do
        assert matcher.call(stub("request", body: '{"a": 1}'))
      end
    end
  end

  describe '#request_json_including predicate' do
    describe "no required attributes" do
      let(:matcher) { request_json_including({}) }

      it "matches an empty body" do
        assert matcher.call(stub("request", body: "{}"))
      end

      it "matches a body with some attributes" do
        assert matcher.call(stub("request", body: '{"a": 1}'))
      end
    end

    describe "one required attribute" do
      let(:matcher) { request_json_including({"a" => 1}) }

      it "does not match an empty body" do
        refute matcher.call(stub("request", body: "{}"))
      end

      it "does not match a body with the required attribute if the value is different" do
        refute matcher.call(stub("request", body: '{"a": 2}'))
      end

      it "matches a body with the required attribute and value" do
        assert matcher.call(stub("request", body: '{"a": 1}'))
      end

      it "matches a body with the required attribute and value and extra attributes" do
        assert matcher.call(stub("request", body: '{"a": 1, "b": 2}'))
      end
    end

    describe "nested required attribute" do
      let(:matcher) { request_json_including({"a" => {"b" => 1}}) }

      it "matches a body with exact same nested hash strucure" do
        assert matcher.call(stub("request", body: '{"a": {"b": 1}}'))
      end

      it "matches a body where the inner hash has the required attribute and an extra one" do
        assert matcher.call(stub("request", body: '{"a": {"b": 1, "c": 2}}'))
      end

      it "does not match a body where the inner hash has the required attribute with the wrong value" do
        refute matcher.call(stub("request", body: '{"a": {"b": 0}}'))
      end

      it "does not match a body where the inner hash lacks the required attribute" do
        refute matcher.call(stub("request", body: '{"a": {"c": 1}}'))
      end
    end

    describe "hash to match uses symbol keys" do
      let(:matcher) { request_json_including({a: {b: 1}}) }

      it "matches a json body" do
        assert matcher.call(stub("request", body: '{"a": {"b": 1}}'))
      end
    end

    describe "nested arrays" do
      let(:matcher) { request_json_including({"a" => [1]}) }

      it "matches a body with exact same inner array" do
        assert matcher.call(stub("request", body: '{"a": [1]}'))
      end

      it "does not match a body with an array with extra elements" do
        refute matcher.call(stub("request", body: '{"a": [1, 2]}'))
      end
    end

    describe "hashes in nested arrays" do
      let(:matcher) { request_json_including({"a" => [{"b" => 1}, 2]}) }

      it "matches a body with exact same inner array" do
        assert matcher.call(stub("request", body: '{"a": [{"b": 1}, 2]}'))
      end

      it "matches a body with an inner hash with extra elements" do
        assert matcher.call(stub("request", body: '{"a": [{"b": 1, "c": 3}, 2]}'))
      end
    end
  end
end
