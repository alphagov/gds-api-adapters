require_relative 'test_helper'
require 'gds_api/panopticon'

describe GdsApi::Panopticon::Registerer do


  describe "creating an instance of the panopticon client" do
    describe "setting the platform" do
      it "should create an instance using the current Plek environment as the platform by default" do
        Plek.stubs(:current).returns(stub(environment: "Something"))

        GdsApi::Panopticon.expects(:new).with("Something", anything()).returns(:panopticon_instance)
        r = GdsApi::Panopticon::Registerer.new({})
        assert_equal :panopticon_instance, r.send(:panopticon)
      end

      it "should allow overriding the platform" do
        Plek.stubs(:current).returns(stub(environment: "Something"))

        GdsApi::Panopticon.expects(:new).with("Something_else", anything()).returns(:panopticon_instance)
        r = GdsApi::Panopticon::Registerer.new({platform: "Something_else"})
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
end
