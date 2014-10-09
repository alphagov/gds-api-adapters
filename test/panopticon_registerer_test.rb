require_relative 'test_helper'
require 'gds_api/panopticon'
require 'gds_api/test_helpers/panopticon'
require 'ostruct'

describe GdsApi::Panopticon::Registerer do
  include GdsApi::TestHelpers::Panopticon

  describe "creating an instance of the panopticon client" do
    describe "setting the platform" do
      it "should create an instance using the current Plek environment as the platform by default" do
        Plek.stubs(:current).returns(stub(find: "http://thisplace"))

        GdsApi::Panopticon.expects(:new).with("http://thisplace", anything()).returns(:panopticon_instance)
        r = GdsApi::Panopticon::Registerer.new({})
        assert_equal :panopticon_instance, r.send(:panopticon)
      end

      it "should pass through the endpoint url" do
        Plek.stubs(:current).returns(stub(find: "http://thisplace"))

        GdsApi::Panopticon.expects(:new).with("http://otherplace", anything()).returns(:panopticon_instance)
        r = GdsApi::Panopticon::Registerer.new({endpoint_url: "http://otherplace"})
        assert_equal :panopticon_instance, r.send(:panopticon)
      end
    end

    describe "setting other options" do
      it "should create an instance with a default timeout of 10 seconds" do
        GdsApi::Panopticon.expects(:new).with(anything(), {timeout: 10}).returns(:panopticon_instance)
        r = GdsApi::Panopticon::Registerer.new({})
        assert_equal :panopticon_instance, r.send(:panopticon)
      end

      it "should allow overriding the timeout" do
        GdsApi::Panopticon.expects(:new).with(anything(), {timeout: 15}).returns(:panopticon_instance)
        r = GdsApi::Panopticon::Registerer.new({timeout: 15})
        assert_equal :panopticon_instance, r.send(:panopticon)
      end

      it "shoule merge in the api credentials" do
        GdsApi::Panopticon::Registerer.any_instance.stubs(:panopticon_api_credentials).returns({foo: "Bar", baz: "kablooie"})
        GdsApi::Panopticon.expects(:new).with(anything(), {timeout: 10, foo: "Bar", baz: "kablooie"}).returns(:panopticon_instance)
        r = GdsApi::Panopticon::Registerer.new({})
        assert_equal :panopticon_instance, r.send(:panopticon)
      end
    end

    it "should memoize the panopticon instance" do
      GdsApi::Panopticon.expects(:new).once.returns(:panopticon_instance)
      r = GdsApi::Panopticon::Registerer.new({})

      assert_equal :panopticon_instance, r.send(:panopticon)
      assert_equal :panopticon_instance, r.send(:panopticon)
    end
  end

  it "should register artefacts" do
    request = stub_artefact_registration('beards',
      slug: 'beards',
      owning_app: 'whitehall',
      kind: 'detailed-guide',
      name: 'A guide to beards',
      description: '5 tips for keeping your beard in check',
      state: 'draft',
      need_ids: ["100001", "100002"]
    )

    GdsApi::Panopticon::Registerer.new(
      owning_app: 'whitehall',
      kind: 'detailed-guide'
    ).register(
      OpenStruct.new(
        slug: 'beards',
        title: 'A guide to beards',
        description: '5 tips for keeping your beard in check',
        state: 'draft',
        need_ids: ["100001", "100002"]
      )
    )

    assert_requested(request)
  end
end
