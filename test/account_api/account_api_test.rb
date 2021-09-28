require "test_helper"
require "gds_api/account_api"
require "gds_api/test_helpers/account_api"

describe GdsApi::AccountApi do
  include GdsApi::TestHelpers::AccountApi

  let(:api_client) { GdsApi::AccountApi.new(Plek.find("account-api")) }
  let(:session_id) { "session-id" }
  let(:new_session_id) { "new-session-id" }

  describe "#get_sign_in_url" do
    it "gives an auth URI" do
      stub_account_api_get_sign_in_url(auth_uri: "https://www.example.com")
      assert_equal("https://www.example.com", api_client.get_sign_in_url.to_hash["auth_uri"])
    end
  end

  describe "#validate_auth_response" do
    it "gives a session ID if the auth response validates" do
      stub_account_api_validates_auth_response(code: "foo", state: "bar")
      assert(!api_client.validate_auth_response(code: "foo", state: "bar")["govuk_account_session"].nil?)
    end

    it "throws a 401 if the auth response does not validate" do
      stub_account_api_rejects_auth_response(code: "foo", state: "bar")

      assert_raises GdsApi::HTTPUnauthorized do
        api_client.validate_auth_response(code: "foo", state: "bar")
      end
    end
  end

  describe "#get_end_session_url" do
    it "gives an end-session URI" do
      stub_account_api_get_end_session_url(end_session_uri: "https://www.example.com/end-session")
      assert_equal("https://www.example.com/end-session", api_client.get_end_session_url.to_hash["end_session_uri"])
    end

    it "passes the GOVUK-Account-Session" do
      stub_account_api_get_end_session_url(govuk_account_session: session_id, end_session_uri: "https://www.example.com/end-session")
      assert_equal("https://www.example.com/end-session", api_client.get_end_session_url(govuk_account_session: session_id).to_hash["end_session_uri"])
    end
  end

  describe "#get_user" do
    it "gets the user's information" do
      stub_account_api_user_info(
        mfa: true,
        email: "user@gov.uk",
        email_verified: false,
        services: { register_to_become_a_wizard: "yes" },
        new_govuk_account_session: new_session_id,
      )
      assert_equal(true, api_client.get_user(govuk_account_session: session_id)["mfa"])
      assert_equal("user@gov.uk", api_client.get_user(govuk_account_session: session_id)["email"])
      assert_equal(false, api_client.get_user(govuk_account_session: session_id)["email_verified"])
      assert_equal("yes", api_client.get_user(govuk_account_session: session_id)["services"]["register_to_become_a_wizard"])
    end

    it "stubs a single service" do
      stub_account_api_user_info_service_state(service: "register_to_become_a_wizard", service_state: "yes_but_must_reauthenticate")
      assert_equal("yes_but_must_reauthenticate", api_client.get_user(govuk_account_session: session_id)["services"]["register_to_become_a_wizard"])
    end
  end

  describe "#delete_user_by_subject_identifier" do
    it "returns 204 if the account is successfully deleted" do
      stub_account_api_delete_user_by_subject_identifier(subject_identifier: "sid")
      assert_equal(204, api_client.delete_user_by_subject_identifier(subject_identifier: "sid").code)
    end

    it "returns 404 if the user cannot be found" do
      stub_account_api_delete_user_by_subject_identifier_does_not_exist(subject_identifier: "sid")
      assert_raises GdsApi::HTTPNotFound do
        api_client.delete_user_by_subject_identifier(subject_identifier: "sid")
      end
    end
  end

  describe "#update_user_by_subject_identifier" do
    it "updates the user's email attributes" do
      stub_update_user_by_subject_identifier(subject_identifier: "sid", email_verified: true, old_email: "email@example.com")
      assert_equal({ "sub" => "sid", "email" => "email@example.com", "email_verified" => true }, api_client.update_user_by_subject_identifier(subject_identifier: "sid", email_verified: true).to_hash)
    end
  end

  describe "email subscriptions" do
    describe "#get_email_subscription" do
      it "returns the subscription details if it exists" do
        stub_account_api_get_email_subscription(name: "foo")
        assert(!api_client.get_email_subscription(name: "foo", govuk_account_session: session_id)["email_subscription"].nil?)
      end

      it "throws a 404 if it does not exist" do
        stub_account_api_get_email_subscription_does_not_exist(name: "foo")
        assert_raises GdsApi::HTTPNotFound do
          api_client.get_email_subscription(name: "foo", govuk_account_session: session_id)
        end
      end
    end

    describe "#put_email_subscription" do
      it "returns the new subscription details" do
        stub_account_api_put_email_subscription(name: "foo", topic_slug: "slug")
        assert(!api_client.put_email_subscription(name: "foo", topic_slug: "slug", govuk_account_session: session_id)["email_subscription"].nil?)
      end
    end

    describe "#delete_email_subscription" do
      it "returns no content if it exists" do
        stub_account_api_delete_email_subscription(name: "foo")
        assert_equal(204, api_client.delete_email_subscription(name: "foo", govuk_account_session: session_id).code)
      end

      it "throws a 404 if it does not exist" do
        stub_account_api_delete_email_subscription_does_not_exist(name: "foo")
        assert_raises GdsApi::HTTPNotFound do
          api_client.delete_email_subscription(name: "foo", govuk_account_session: session_id)
        end
      end
    end
  end

  describe "attributes" do
    describe "#get_attributes" do
      describe "attributes exist" do
        before { stub_account_api_has_attributes(attributes: attributes.keys, values: attributes, new_govuk_account_session: new_session_id) }

        let(:attributes) { { "foo" => { "bar" => %w[baz] } } }

        it "returns the attribute values" do
          assert(api_client.get_attributes(attributes: attributes.keys, govuk_account_session: session_id)["values"] == attributes)
        end

        it "returns the new session value" do
          assert_equal(new_session_id, api_client.get_attributes(attributes: attributes.keys, govuk_account_session: session_id)["govuk_account_session"])
        end
      end
    end

    describe "#set_attributes" do
      it "returns a new session when setting attributes" do
        stub_account_api_set_attributes(attributes: { foo: %w[bar] }, new_govuk_account_session: new_session_id)
        assert_equal(new_session_id, api_client.set_attributes(govuk_account_session: session_id, attributes: { foo: %w[bar] }).to_hash["govuk_account_session"])
      end
    end
  end

  describe "the user is not logged in or their session is invalid" do
    it "throws a 401 if the user checks their information" do
      stub_account_api_unauthorized_user_info
      assert_raises GdsApi::HTTPUnauthorized do
        api_client.get_user(govuk_account_session: session_id)
      end
    end

    it "throws a 401 if the user gets their attributes" do
      stub_account_api_unauthorized_has_attributes(attributes: %w[foo bar baz])
      assert_raises GdsApi::HTTPUnauthorized do
        api_client.get_attributes(attributes: %w[foo bar baz], govuk_account_session: session_id)
      end
    end

    it "throws a 401 if the user updates their attributes" do
      stub_account_api_unauthorized_set_attributes(attributes: { foo: %w[bar baz] })
      assert_raises GdsApi::HTTPUnauthorized do
        api_client.set_attributes(attributes: { foo: %w[bar baz] }, govuk_account_session: session_id)
      end
    end

    it "throws a 401 if the user gets an email subscription" do
      stub_account_api_unauthorized_get_email_subscription(name: "foo")
      assert_raises GdsApi::HTTPUnauthorized do
        api_client.get_email_subscription(name: "foo", govuk_account_session: session_id)
      end
    end

    it "throws a 401 if the user updates an email subscription" do
      stub_account_api_unauthorized_put_email_subscription(name: "foo")
      assert_raises GdsApi::HTTPUnauthorized do
        api_client.put_email_subscription(name: "foo", topic_slug: "slug", govuk_account_session: session_id)
      end
    end

    it "throws a 401 if the user deletes an email subscription" do
      stub_account_api_unauthorized_delete_email_subscription(name: "foo")
      assert_raises GdsApi::HTTPUnauthorized do
        api_client.delete_email_subscription(name: "foo", govuk_account_session: session_id)
      end
    end
  end

  describe "the user is logged in without MFA when it's needed" do
    it "throws a 403 if the user gets their attributes" do
      stub_account_api_forbidden_has_attributes(attributes: %w[foo bar baz])
      assert_raises GdsApi::HTTPForbidden do
        api_client.get_attributes(attributes: %w[foo bar baz], govuk_account_session: session_id)
      end
    end

    it "throws a 403 if the user updates their attributes" do
      stub_account_api_forbidden_set_attributes(attributes: { foo: %w[bar baz] })
      assert_raises GdsApi::HTTPForbidden do
        api_client.set_attributes(attributes: { foo: %w[bar baz] }, govuk_account_session: session_id)
      end
    end
  end
end
