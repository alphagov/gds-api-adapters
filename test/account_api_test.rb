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

    it "responds with 200 OK and includes the cookie_consent in the response, if saved" do
      response_body = response_body_with_session_identifier.merge(cookie_consent: true)

      account_api
        .given("there is a valid OAuth response, with cookie consent 'true'")
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

  describe "#update_user_by_subject_identifier" do
    let(:subject_identifier) { "the-subject-identifier" }
    let(:path) { "/api/oidc-users/#{subject_identifier}" }

    before do
      email_attributes = {
        email: "example.email.address@gov.uk",
        email_verified: true,
        has_unconfirmed_email: false,
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

  describe "the user is logged in" do
    let(:govuk_account_session) { "logged-in-user-session" }

    describe "#get_user" do
      let(:path) { "/api/user" }

      it "responds with 200 OK" do
        user_details = response_body_with_session_identifier.merge(
          id: Pact.like("user-id"),
          level_of_authentication: Pact.like("level0"),
          email: Pact.like("user@example.com"),
          email_verified: Pact.like(true),
          has_unconfirmed_email: Pact.like(true),
          services: {
            transition_checker: "no",
            saved_pages: "no",
          },
        )

        account_api
          .given("there is a valid user session")
          .upon_receiving("a get-user request")
          .with(method: :get, path: path, headers: headers)
          .will_respond_with(status: 200, headers: json_response_headers, body: user_details)

        api_client.get_user(govuk_account_session: govuk_account_session)
      end

      it "includes 'saved_pages: yes' if the user has saved pages" do
        account_api
          .given("there is a valid user session, with /guidance/some-govuk-guidance saved")
          .upon_receiving("a get-user request")
          .with(method: :get, path: path, headers: headers)
          .will_respond_with(status: 200, headers: json_response_headers, body: { services: { saved_pages: "yes" } })

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
        let(:attribute_name) { "test_attribute_1" }

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
          response_body = response_body_with_session_identifier.merge(values: { attribute_name => { bar: "baz" } })

          account_api
            .given("there is a valid user session, with an attribute called '#{attribute_name}'")
            .upon_receiving("a get-attributes request")
            .with(method: :get, path: path, headers: headers, query: { "attributes[]" => [attribute_name] })
            .will_respond_with(status: 200, headers: json_response_headers, body: response_body)

          api_client.get_attributes(govuk_account_session: govuk_account_session, attributes: [attribute_name])
        end
      end

      describe "#set_attributes" do
        let(:attributes) { { test_attribute_1: [1, 2, 3], test_attribute_2: { nested: "json" } } }

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

    describe "#get_attributes_names" do
      let(:path) { "/api/attributes/names" }
      let(:attribute_name) { "test_attribute_1" }

      it "responds with 200 OK and no attributes, if none exist" do
        response_body = response_body_with_session_identifier.merge(values: [])

        account_api
          .given("there is a valid user session")
          .upon_receiving("a get-attributes-names request")
          .with(method: :get, path: path, headers: headers, query: { "attributes[]" => [attribute_name] })
          .will_respond_with(status: 200, headers: json_response_headers, body: response_body)

        api_client.get_attributes_names(govuk_account_session: govuk_account_session, attributes: [attribute_name])
      end

      it "responds with 200 OK and the attribute names, if they exist" do
        response_body = response_body_with_session_identifier.merge(values: [attribute_name])

        account_api
          .given("there is a valid user session, with an attribute called '#{attribute_name}'")
          .upon_receiving("a get-attributes-names request")
          .with(method: :get, path: path, headers: headers, query: { "attributes[]" => [attribute_name] })
          .will_respond_with(status: 200, headers: json_response_headers, body: response_body)

        api_client.get_attributes_names(govuk_account_session: govuk_account_session, attributes: [attribute_name])
      end
    end
  end

  describe "saved pages" do
    let(:saved_page_path) { "/guidance/some-govuk-guidance" }
    let(:path) { "/api/saved-pages/#{CGI.escape(saved_page_path)}" }

    describe "#get_saved_pages" do
      let(:path) { "/api/saved-pages" }

      it "responds with 200 OK and returns an empty list of saved pages, if none exist" do
        response_body = response_body_with_session_identifier.merge(saved_pages: [])

        account_api
          .given("there is a valid user session")
          .upon_receiving("a GET saved_pages request")
          .with(method: :get, path: path, headers: headers)
          .will_respond_with(status: 200, headers: json_response_headers, body: response_body)

        api_client.get_saved_pages(govuk_account_session: govuk_account_session)
      end

      it "responds with 200 OK and a list of saved pages, if some exist" do
        response_body = response_body_with_session_identifier.merge(
          saved_pages: [
            {
              page_path: "/page-path/1",
              content_id: Pact.like("7b7b77b0-257a-467d-84c9-c5167781d05c"),
              title: Pact.like("Page #1"),
            },
            {
              page_path: "/page-path/2",
              content_id: Pact.like("7b7b77b0-257a-467d-84c9-c5167781d05c"),
              title: Pact.like("Page #1"),
            },
          ],
        )

        account_api
          .given("there is a valid user session, with saved pages")
          .upon_receiving("a GET saved_pages request")
          .with(method: :get, path: path, headers: headers)
          .will_respond_with(status: 200, headers: json_response_headers, body: response_body)

        api_client.get_saved_pages(govuk_account_session: govuk_account_session)
      end
    end

    describe "#get_saved_page" do
      it "responds with 200 OK and the saved page, if it exists" do
        response_body = response_body_with_session_identifier.merge(
          saved_page: {
            page_path: saved_page_path,
            content_id: Pact.like("6e0e144a-9e59-4ac8-af3b-d87e8ff30a47"),
            title: Pact.like("Some GOV.UK Guidance"),
          },
        )

        account_api
          .given("there is a valid user session, with '#{saved_page_path}' saved")
          .upon_receiving("a GET saved-page/:page_path request")
          .with(method: :get, path: path, headers: headers)
          .will_respond_with(status: 200, headers: json_response_headers, body: response_body)

        api_client.get_saved_page(page_path: saved_page_path, govuk_account_session: govuk_account_session)
      end

      it "responds with 404 Not Found if there is not a saved page" do
        account_api
          .given("there is a valid user session")
          .upon_receiving("a GET saved-page/:page_path request")
          .with(method: :get, path: path, headers: headers)
          .will_respond_with(status: 404)

        assert_raises GdsApi::HTTPNotFound do
          api_client.get_saved_page(page_path: saved_page_path, govuk_account_session: govuk_account_session)
        end
      end
    end

    describe "#save_page" do
      it "responds with 200 OK and the saved page" do
        response_body = response_body_with_session_identifier.merge(
          saved_page: {
            page_path: saved_page_path,
            content_id: Pact.like("6e0e144a-9e59-4ac8-af3b-d87e8ff30a47"),
            title: Pact.like("Some GOV.UK Guidance"),
          },
        )

        account_api
          .given("there is a valid user session")
          .upon_receiving("a PUT saved-page/:page_path request")
          .with(method: :put, path: path, headers: headers)
          .will_respond_with(status: 200, headers: json_response_headers, body: response_body)

        api_client.save_page(page_path: saved_page_path, govuk_account_session: govuk_account_session)
      end

      it "responds with 200 OK and updates an existing saved page" do
        response_body = response_body_with_session_identifier.merge(
          saved_page: {
            page_path: saved_page_path,
            content_id: Pact.like("6e0e144a-9e59-4ac8-af3b-d87e8ff30a47"),
            title: Pact.like("Some GOV.UK Guidance"),
          },
        )

        account_api
          .given("there is a valid user session, with '#{saved_page_path}' saved")
          .upon_receiving("a PUT saved-page/:page_path request")
          .with(method: :put, path: path, headers: headers)
          .will_respond_with(status: 200, headers: json_response_headers, body: response_body)

        api_client.save_page(page_path: saved_page_path, govuk_account_session: govuk_account_session)
      end
    end

    describe "#delete_saved_page" do
      it "responds with 204 No Content if there is a saved page" do
        account_api
          .given("there is a valid user session, with '#{saved_page_path}' saved")
          .upon_receiving("a DELETE saved-page/:page_path request")
          .with(method: :delete, path: path, headers: headers)
          .will_respond_with(status: 204)

        api_client.delete_saved_page(page_path: saved_page_path, govuk_account_session: govuk_account_session)
      end

      it "responds with 404 Not Found if there is not a saved page" do
        account_api
          .given("there is a valid user session")
          .upon_receiving("a DELETE saved-page/:page_path request")
          .with(method: :delete, path: path, headers: headers)
          .will_respond_with(status: 404)

        assert_raises GdsApi::HTTPNotFound do
          api_client.delete_saved_page(page_path: saved_page_path, govuk_account_session: govuk_account_session)
        end
      end
    end
  end
end
