require "test_helper"
require "gds_api/account_api"

describe GdsApi::AccountApi do
  include PactTest

  let(:api_client) { GdsApi::AccountApi.new(account_api_host) }

  let(:govuk_account_session) { nil }

  let(:headers) { GdsApi::JsonClient.default_request_headers.merge({ "GOVUK-Account-Session" => govuk_account_session }.compact) }
  let(:headers_with_json_body) { GdsApi::JsonClient.default_request_with_json_body_headers.merge({ "GOVUK-Account-Session" => govuk_account_session }.compact) }

  let(:json_response_headers) { { "Content-Type" => "application/json; charset=utf-8" } }

  let(:response_body_with_session_identifier) { { govuk_account_session: Pact.like("user-session-id") } }

  describe "#get_sign_in_url" do
    let(:path) { "/api/oauth2/sign-in" }

    it "responds with 200 OK, an authentication URI, and a state for CSRF protection" do
      response_body = {
        auth_uri: Pact.like("http://authentication-provider/some/oauth/url"),
        state: Pact.like("value-to-use-for-csrf-prevention"),
      }

      account_api
        .upon_receiving("a sign-in request")
        .with(method: :get, path: path, headers: headers)
        .will_respond_with(status: 200, headers: json_response_headers, body: response_body)

      api_client.get_sign_in_url
    end
  end

  describe "#validate_auth_response" do
    let(:path) { "/api/oauth2/callback" }
    let(:params) { { code: "code", state: "state" } }

    it "responds with 200 OK and a govuk_account_session if the parameters are valid" do
      account_api
        .given("there is a valid OAuth response")
        .upon_receiving("a validation request")
        .with(method: :post, path: path, headers: headers_with_json_body, body: params)
        .will_respond_with(status: 200, headers: json_response_headers, body: response_body_with_session_identifier)

      api_client.validate_auth_response(**params)
    end

    it "responds with 200 OK and includes the redirect_path in the response, if given" do
      redirect_path = "/some-arbitrary-path"
      response_body = response_body_with_session_identifier.merge(redirect_path: redirect_path)

      account_api
        .given("there is a valid OAuth response, with the redirect path '#{redirect_path}'")
        .upon_receiving("a validation request")
        .with(method: :post, path: path, headers: headers_with_json_body, body: params)
        .will_respond_with(status: 200, headers: json_response_headers, body: response_body)

      api_client.validate_auth_response(**params)
    end

    it "responds with 401 Unauthorized if the parameters are not valid" do
      account_api
        .upon_receiving("a validation request")
        .with(method: :post, path: path, headers: headers_with_json_body, body: params)
        .will_respond_with(status: 401)

      assert_raises GdsApi::HTTPUnauthorized do
        api_client.validate_auth_response(**params)
      end
    end
  end

  describe "#get_end_session_url" do
    let(:path) { "/api/oauth2/end-session" }

    it "responds with 200 OK and an end-session URI" do
      response_body = {
        end_session_uri: Pact.like("http://authentication-provider/some/end/session/url"),
      }

      account_api
        .upon_receiving("an end-session request")
        .with(method: :get, path: path, headers: headers)
        .will_respond_with(status: 200, headers: json_response_headers, body: response_body)

      api_client.get_end_session_url
    end
  end

  describe "#update_user_by_subject_identifier" do
    let(:subject_identifier) { "the-subject-identifier" }
    let(:path) { "/api/oidc-users/#{subject_identifier}" }

    before do
      email_attributes = {
        email: "example.email.address@gov.uk",
        email_verified: true,
      }
      response_body = email_attributes.merge(sub: subject_identifier)

      account_api
        .upon_receiving("a request to change the user's email attributes")
        .with(method: :patch, path: path, headers: headers_with_json_body, body: email_attributes)
        .will_respond_with(status: 200, headers: json_response_headers, body: response_body)

      api_client.update_user_by_subject_identifier(
        subject_identifier: subject_identifier,
        **email_attributes,
      )
    end
  end

  describe "#delete_user_by_subject_identifier" do
    let(:subject_identifier) { "the-subject-identifier" }
    let(:path) { "/api/oidc-users/#{subject_identifier}" }

    it "responds with 204 No Content if the user existed and has been deleted" do
      account_api
        .given("there is a user with subject identifier '#{subject_identifier}'")
        .upon_receiving("a delete-user request for '#{subject_identifier}'")
        .with(method: :delete, path: path, headers: headers)
        .will_respond_with(status: 204)

      api_client.delete_user_by_subject_identifier(subject_identifier: subject_identifier)
    end

    it "responds with 404 if the user does not exist" do
      account_api
        .upon_receiving("a delete-user request")
        .with(method: :delete, path: path, headers: headers)
        .will_respond_with(status: 404)

      assert_raises GdsApi::HTTPNotFound do
        api_client.delete_user_by_subject_identifier(subject_identifier: subject_identifier)
      end
    end
  end

  describe "#match_user_by_email" do
    let(:email) { "email@example.com" }
    let(:path) { "/api/user/match-by-email" }

    it "responds with `match: false` if the user exists" do
      account_api
        .given("there is a user with email address '#{email}'")
        .upon_receiving("a match-user-by-email request for '#{email}'")
        .with(method: :get, path: path, headers: headers, query: { email: email })
        .will_respond_with(status: 200, headers: json_response_headers, body: { match: Pact.like(false) })

      api_client.match_user_by_email(email: email)
    end

    it "responds with 404 if the user does not exist" do
      account_api
        .upon_receiving("a match-user-by-email request for '#{email}'")
        .with(method: :get, path: path, headers: headers, query: { email: email })
        .will_respond_with(status: 404)

      assert_raises GdsApi::HTTPNotFound do
        api_client.match_user_by_email(email: email)
      end
    end
  end

  describe "the user is logged in" do
    let(:govuk_account_session) { "logged-in-user-session" }

    describe "#get_user" do
      let(:path) { "/api/user" }

      it "responds with 200 OK" do
        user_details = response_body_with_session_identifier.merge(
          id: Pact.like("user-id"),
          mfa: Pact.like(true),
          email: Pact.like("user@example.com"),
          email_verified: Pact.like(true),
        )

        account_api
          .given("there is a valid user session")
          .upon_receiving("a get-user request")
          .with(method: :get, path: path, headers: headers)
          .will_respond_with(status: 200, headers: json_response_headers, body: user_details)

        api_client.get_user(govuk_account_session: govuk_account_session)
      end
    end

    describe "email subscriptions" do
      let(:subscription_name) { "wizard-news" }
      let(:path) { "/api/email-subscriptions/#{subscription_name}" }

      describe "#get_email_subscription" do
        it "responds with 200 OK if there is a subscription" do
          subscription_json = {
            name: subscription_name,
            topic_slug: Pact.like("wizard-news-topic-slug"),
          }

          account_api
            .given("there is a valid user session, with a '#{subscription_name}' email subscription")
            .upon_receiving("a show-subscription request for '#{subscription_name}'")
            .with(method: :get, path: path, headers: headers)
            .will_respond_with(status: 200, headers: json_response_headers, body: { email_subscription: subscription_json })

          api_client.get_email_subscription(name: subscription_name, govuk_account_session: govuk_account_session)
        end

        it "responds with 404 Not Found if there is not a subscription" do
          account_api
            .given("there is a valid user session")
            .upon_receiving("a show-subscription request for '#{subscription_name}'")
            .with(method: :get, path: path, headers: headers)
            .will_respond_with(status: 404)

          assert_raises GdsApi::HTTPNotFound do
            api_client.get_email_subscription(name: subscription_name, govuk_account_session: govuk_account_session)
          end
        end
      end

      describe "#put_email_subscription" do
        let(:topic_slug) { "wizard-news-topic-slug" }
        let(:subscription_json) { { name: subscription_name, topic_slug: topic_slug } }

        it "responds with 200 OK" do
          response_body = response_body_with_session_identifier.merge(email_subscription: subscription_json)

          account_api
            .given("there is a valid user session")
            .upon_receiving("a put-subscription request for '#{subscription_name}'")
            .with(method: :put, path: path, headers: headers_with_json_body, body: { topic_slug: topic_slug })
            .will_respond_with(status: 200, headers: json_response_headers, body: response_body)

          api_client.put_email_subscription(name: subscription_name, topic_slug: topic_slug, govuk_account_session: govuk_account_session)
        end

        it "responds with 200 OK and updates an existing subscription" do
          response_body = response_body_with_session_identifier.merge(email_subscription: subscription_json)

          account_api
            .given("there is a valid user session, with a '#{subscription_name}' email subscription")
            .upon_receiving("a put-subscription request for '#{subscription_name}'")
            .with(method: :put, path: path, headers: headers_with_json_body, body: { topic_slug: topic_slug })
            .will_respond_with(status: 200, headers: json_response_headers, body: response_body)

          api_client.put_email_subscription(name: subscription_name, topic_slug: topic_slug, govuk_account_session: govuk_account_session)
        end
      end

      describe "#delete_email_subscription" do
        it "responds with 204 No Content if there is a subscription" do
          account_api
            .given("there is a valid user session, with a '#{subscription_name}' email subscription")
            .upon_receiving("a delete-subscription request for '#{subscription_name}'")
            .with(method: :delete, path: path, headers: headers)
            .will_respond_with(status: 204)

          api_client.delete_email_subscription(name: subscription_name, govuk_account_session: govuk_account_session)
        end

        it "responds with 404 Not Found if there is not a subscription" do
          account_api
            .given("there is a valid user session")
            .upon_receiving("a delete-subscription request for '#{subscription_name}'")
            .with(method: :delete, path: path, headers: headers)
            .will_respond_with(status: 404)

          assert_raises GdsApi::HTTPNotFound do
            api_client.delete_email_subscription(name: subscription_name, govuk_account_session: govuk_account_session)
          end
        end
      end
    end

    describe "attributes" do
      let(:path) { "/api/attributes" }

      describe "#get_attributes" do
        let(:attribute_name) { "local_attribute" }

        it "responds with 200 OK and no attributes, if none exist" do
          response_body = response_body_with_session_identifier.merge(values: {})

          account_api
            .given("there is a valid user session")
            .upon_receiving("a get-attributes request")
            .with(method: :get, path: path, headers: headers, query: { "attributes[]" => [attribute_name] })
            .will_respond_with(status: 200, headers: json_response_headers, body: response_body)

          api_client.get_attributes(govuk_account_session: govuk_account_session, attributes: [attribute_name])
        end

        it "responds with 200 OK and the attributes, if some exist" do
          response_body = response_body_with_session_identifier.merge(values: { attribute_name => true })

          account_api
            .given("there is a valid user session, with an attribute called '#{attribute_name}'")
            .upon_receiving("a get-attributes request")
            .with(method: :get, path: path, headers: headers, query: { "attributes[]" => [attribute_name] })
            .will_respond_with(status: 200, headers: json_response_headers, body: response_body)

          api_client.get_attributes(govuk_account_session: govuk_account_session, attributes: [attribute_name])
        end
      end

      describe "#set_attributes" do
        let(:attributes) { { local_attribute: true } }

        it "responds with 200 OK" do
          account_api
            .given("there is a valid user session")
            .upon_receiving("a set-attributes request")
            .with(method: :patch, path: path, headers: headers_with_json_body, body: { attributes: attributes })
            .will_respond_with(status: 200, headers: json_response_headers, body: response_body_with_session_identifier)

          api_client.set_attributes(govuk_account_session: govuk_account_session, attributes: attributes)
        end
      end
    end
  end
end
