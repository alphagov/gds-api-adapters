require "test_helper"
require "gds_api/account_api"
require "gds_api/test_helpers/account_api"

describe GdsApi::AccountApi do
  include GdsApi::TestHelpers::AccountApi

  let(:base_url)      { Plek.find("account-api") }
  let(:api_client)    { GdsApi::AccountApi.new(base_url) }

  it "gets a sign in URL" do
    stub_account_api_get_sign_in_url(auth_uri: "https://www.example.com")
    assert_equal("https://www.example.com", api_client.get_sign_in_url.to_hash["auth_uri"])
  end

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

  it "gets a state ID" do
    stub_account_api_create_registration_state(attributes: { foo: "bar" }, state_id: "state-id")
    assert_equal("state-id", api_client.create_registration_state(attributes: { foo: "bar" }).to_hash["state_id"])
  end

  describe "a transition checker subscription exists" do
    before { stub_account_api_has_email_subscription(new_govuk_account_session: "new-session") }

    it "checks if the user has an email subscription" do
      assert(api_client.check_for_email_subscription(govuk_account_session: "foo")["has_subscription"])
    end

    it "returns the new session value" do
      assert_equal("new-session", api_client.check_for_email_subscription(govuk_account_session: "foo")["govuk_account_session"])
    end
  end

  describe "a transition checker subscription does not exist" do
    before { stub_account_api_does_not_have_email_subscription(new_govuk_account_session: "new-session") }

    it "checks if the user has an email subscription" do
      assert(api_client.check_for_email_subscription(govuk_account_session: "foo")["has_subscription"] == false)
    end

    it "returns the new session value" do
      assert_equal("new-session", api_client.check_for_email_subscription(govuk_account_session: "foo")["govuk_account_session"])
    end
  end

  it "returns a new session when setting the email subscription" do
    stub_account_api_set_email_subscription(new_govuk_account_session: "new-session")
    assert_equal("new-session", api_client.set_email_subscription(govuk_account_session: "foo", slug: "slug").to_hash["govuk_account_session"])
  end
end
