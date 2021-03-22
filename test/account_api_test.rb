require "test_helper"
require "gds_api/account_api"

describe GdsApi::AccountApi do
  include PactTest

  let(:api_client) { GdsApi::AccountApi.new(account_api_host) }

  let(:authenticated_headers) { { "GOVUK-Account-Session" => govuk_account_session } }
  let(:govuk_account_session) { "logged-in-user-session" }

  describe "getting a sign-in URL" do
    let(:redirect_path) { nil }

    before do
      account_api
        .upon_receiving("a sign-in request")
        .with(
          method: :get,
          path: "/api/oauth2/sign-in",
          headers: GdsApi::JsonClient.default_request_headers,
        )
        .will_respond_with(
          status: 200,
          headers: { "Content-Type" => "application/json; charset=utf-8" },
          body: {
            auth_uri: Pact.like("http://authentication-provider/some/oauth/url"),
            state: Pact.like("value-to-use-for-csrf-prevention"),
          },
        )
    end

    it "responds with 200 OK, an authentication URI, and a state for CSRF protection" do
      response = api_client.get_sign_in_url
      assert response["auth_uri"].present?
      assert response["state"].present?
      assert_equal 200, response.code
    end
  end

  describe "validating an OAuth response" do
    before do
      account_api
        .given("there is a valid OAuth response")
        .upon_receiving("a validation request")
        .with(
          method: :post,
          path: "/api/oauth2/callback",
          body: {
            code: "code",
            state: "state",
          },
          headers: GdsApi::JsonClient.default_request_with_json_body_headers,
        )
        .will_respond_with(
          status: 200,
          headers: { "Content-Type" => "application/json; charset=utf-8" },
          body: {
            govuk_account_session: Pact.like("user-session-id"),
          },
        )
    end

    it "responds with 200 OK and a govuk_account_session" do
      response = api_client.validate_auth_response(code: "code", state: "state")
      assert response["govuk_account_session"].present?
      assert response["redirect_path"].nil?
      assert_equal 200, response.code
    end
  end

  describe "validating an OAuth response with a redirect path" do
    let(:redirect_path) { "/some-arbitrary-path" }

    before do
      account_api
        .given("there is a valid OAuth response, with the redirect path '/some-arbitrary-path'")
        .upon_receiving("a validation request")
        .with(
          method: :post,
          path: "/api/oauth2/callback",
          body: {
            code: "code",
            state: "state",
          },
          headers: GdsApi::JsonClient.default_request_with_json_body_headers,
        )
        .will_respond_with(
          status: 200,
          headers: { "Content-Type" => "application/json; charset=utf-8" },
          body: {
            govuk_account_session: Pact.like("user-session-id"),
            redirect_path: Pact.like(redirect_path),
          },
        )
    end

    it "responds with a redirect_path" do
      response = api_client.validate_auth_response(code: "code", state: "state")
      assert_equal redirect_path, response["redirect_path"]
    end
  end

  describe "creating a registration state" do
    let(:attributes) { { foo: "bar" } }

    before do
      account_api
        .upon_receiving("a create-state request")
        .with(
          method: :post,
          path: "/api/oauth2/state",
          body: { attributes: attributes },
          headers: GdsApi::JsonClient.default_request_with_json_body_headers,
        )
        .will_respond_with(
          status: 200,
          headers: { "Content-Type" => "application/json; charset=utf-8" },
          body: {
            state_id: Pact.like("reference-to-pass-to-get_sign_in_url"),
          },
        )
    end

    it "responds with 200 OK and a state_id" do
      response = api_client.create_registration_state(attributes: attributes)
      assert response["state_id"].present?
      assert_equal 200, response.code
    end
  end

  describe "checking for a transition checker email subscription" do
    describe "the user is logged in" do
      let(:given) { "there is a valid user session" }
      let(:has_subscription) { false }

      before do
        account_api
          .given(given)
          .upon_receiving("a has-subscription request")
          .with(
            method: :get,
            path: "/api/transition-checker-email-subscription",
            headers: GdsApi::JsonClient.default_request_headers.merge(authenticated_headers),
          )
          .will_respond_with(
            status: 200,
            headers: { "Content-Type" => "application/json; charset=utf-8" },
            body: {
              govuk_account_session: Pact.like("user-session-id"),
              has_subscription: has_subscription,
            },
          )
      end

      it "responds with 200 OK, a new govuk_account_session, and says that the subscription does not exist" do
        response = api_client.check_for_email_subscription(govuk_account_session: govuk_account_session)
        assert response["govuk_account_session"].present?
        assert_equal false, response["has_subscription"]
        assert_equal 200, response.code
      end

      describe "a subscription exists" do
        let(:given) { "there is a valid user session, with a transition checker email subscription" }
        let(:has_subscription) { true }

        it "says that the subscription exists" do
          response = api_client.check_for_email_subscription(govuk_account_session: govuk_account_session)
          assert response["has_subscription"]
        end
      end
    end
  end

  describe "setting the transition checker email subscription" do
    describe "the user is logged in" do
      before do
        account_api
          .given("there is a valid user session")
          .upon_receiving("a set-subscription request")
          .with(
            method: :post,
            path: "/api/transition-checker-email-subscription",
            body: { slug: "brexit-emails-123" },
            headers: GdsApi::JsonClient.default_request_with_json_body_headers.merge(authenticated_headers),
          )
          .will_respond_with(
            status: 200,
            headers: { "Content-Type" => "application/json; charset=utf-8" },
            body: {
              govuk_account_session: Pact.like("user-session-id"),
            },
          )
      end

      it "responds with 200 OK and a new govuk_account_session" do
        response = api_client.set_email_subscription(govuk_account_session: govuk_account_session, slug: "brexit-emails-123")
        assert response["govuk_account_session"].present?
        assert_equal 200, response.code
      end
    end
  end

  describe "fetching attribute values" do
    describe "the user is logged in" do
      let(:given) { "there is a valid user session" }
      let(:attributes) { {} }

      before do
        account_api
          .given(given)
          .upon_receiving("a get-attributes request")
          .with(
            method: :get,
            path: "/api/attributes",
            query: { "attributes[]" => %w[foo] },
            headers: GdsApi::JsonClient.default_request_headers.merge(authenticated_headers),
          )
          .will_respond_with(
            status: 200,
            headers: { "Content-Type" => "application/json; charset=utf-8" },
            body: {
              govuk_account_session: Pact.like("user-session-id"),
              values: attributes,
            },
          )
      end

      it "responds with 200 OK, a new govuk_account_session, and no attributes" do
        response = api_client.get_attributes(govuk_account_session: govuk_account_session, attributes: %w[foo])
        assert response["govuk_account_session"].present?
        assert_equal attributes, response["values"]
        assert_equal 200, response.code
      end

      describe "attributes exist" do
        let(:given) { "there is a valid user session, with an attribute called 'foo'" }
        let(:attributes) { { foo: { bar: "baz" } } }

        it "responds with the attribute values" do
          response = api_client.get_attributes(govuk_account_session: govuk_account_session, attributes: %w[foo])
          assert_equal attributes[:foo][:bar], response["values"]["foo"]["bar"]
        end
      end
    end
  end

  describe "setting attribute values" do
    let(:attributes) { { foo: [1, 2, 3], bar: { nested: "json" } } }

    describe "the user is logged in" do
      before do
        account_api
          .given("there is a valid user session")
          .upon_receiving("a set-attributes request")
          .with(
            method: :patch,
            path: "/api/attributes",
            body: { attributes: attributes },
            headers: GdsApi::JsonClient.default_request_with_json_body_headers.merge(authenticated_headers),
          )
          .will_respond_with(
            status: 200,
            headers: { "Content-Type" => "application/json; charset=utf-8" },
            body: {
              govuk_account_session: Pact.like("user-session-id"),
            },
          )
      end

      it "responds with 200 OK and a new govuk_account_session" do
        response = api_client.set_attributes(govuk_account_session: govuk_account_session, attributes: attributes)
        assert response["govuk_account_session"].present?
        assert_equal 200, response.code
      end
    end
  end
end
