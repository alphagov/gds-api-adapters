require "test_helper"
require "gds_api/account_api"

describe GdsApi::AccountApi do
  include PactTest

  let(:api_client) { GdsApi::AccountApi.new(account_api_host) }

  let(:authenticated_headers) { { "GOVUK-Account-Session" => govuk_account_session } }
  let(:govuk_account_session) { "logged-in-user-session" }

  describe "getting a sign-in URL" do
    it "responds with 200 OK, an authentication URI, and a state for CSRF protection" do
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

      api_client.get_sign_in_url
    end
  end

  describe "validating an OAuth response" do
    it "responds with 200 OK and a govuk_account_session" do
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

      api_client.validate_auth_response(code: "code", state: "state")
    end
  end

  describe "validating an OAuth response with a redirect path" do
    let(:redirect_path) { "/some-arbitrary-path" }

    it "responds with a redirect_path" do
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

      api_client.validate_auth_response(code: "code", state: "state")
    end
  end

  describe "creating a registration state" do
    let(:attributes) { { foo: "bar" } }

    it "responds with 200 OK and a state_id" do
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

      api_client.create_registration_state(attributes: attributes)
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
        api_client.check_for_email_subscription(govuk_account_session: govuk_account_session)
      end

      describe "a subscription exists" do
        let(:given) { "there is a valid user session, with a transition checker email subscription" }
        let(:has_subscription) { true }

        it "says that the subscription exists" do
          api_client.check_for_email_subscription(govuk_account_session: govuk_account_session)
        end
      end
    end
  end

  describe "setting the transition checker email subscription" do
    describe "the user is logged in" do
      it "responds with 200 OK and a new govuk_account_session" do
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

        api_client.set_email_subscription(govuk_account_session: govuk_account_session, slug: "brexit-emails-123")
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
        api_client.get_attributes(govuk_account_session: govuk_account_session, attributes: %w[foo])
      end

      describe "attributes exist" do
        let(:given) { "there is a valid user session, with an attribute called 'foo'" }
        let(:attributes) { { foo: { bar: "baz" } } }

        it "responds with the attribute values" do
          api_client.get_attributes(govuk_account_session: govuk_account_session, attributes: %w[foo])
        end
      end
    end
  end

  describe "setting attribute values" do
    let(:attributes) { { foo: [1, 2, 3], bar: { nested: "json" } } }

    describe "the user is logged in" do
      it "responds with 200 OK and a new govuk_account_session" do
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

        api_client.set_attributes(govuk_account_session: govuk_account_session, attributes: attributes)
      end
    end
  end

  describe "fetching attribute names" do
    describe "the user is logged in" do
      before do
        account_api
          .given(given)
          .upon_receiving("a get-attributes-names request")
          .with(
            method: :get,
            path: "/api/attributes/names",
            query: { "attributes[]" => queried_attribute_names },
            headers: GdsApi::JsonClient.default_request_headers.merge(authenticated_headers),
          )
          .will_respond_with(
            status: 200,
            headers: { "Content-Type" => "application/json; charset=utf-8" },
            body: {
              govuk_account_session: Pact.like("user-session-id"),
              values: returned_attribute_names,
            },
          )
      end

      let(:queried_attribute_names) { %w[foo] }
      let(:response) { api_client.get_attributes_names(govuk_account_session: govuk_account_session, attributes: queried_attribute_names) }

      describe "attributes do not exist" do
        let(:given) { "there is a valid user session" }
        let(:returned_attribute_names) { [] }

        it "responds with 200 OK, a new govuk_account_session, and no attributes" do
          assert response["govuk_account_session"].present?
          assert_equal returned_attribute_names, response["values"]
          assert_equal 200, response.code
        end
      end

      describe "attributes exist" do
        let(:given) { "there is a valid user session, with an attribute called 'foo'" }
        let(:returned_attribute_names) { %w[foo] }

        it "responds with the attribute values" do
          assert_equal returned_attribute_names, response["values"]
        end
      end
    end
  end
end
