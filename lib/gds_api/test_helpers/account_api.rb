require "json"

module GdsApi
  module TestHelpers
    module AccountApi
      ACCOUNT_API_ENDPOINT = Plek.find("account-api")

      def stub_account_api_get_sign_in_url(redirect_path: nil, state_id: nil, auth_uri: "http://auth/provider", state: "state")
        querystring = Rack::Utils.build_nested_query({ redirect_path: redirect_path, state_id: state_id }.compact)
        stub_request(:get, "#{ACCOUNT_API_ENDPOINT}/api/oauth2/sign-in?#{querystring}")
          .to_return(
            status: 200,
            body: { auth_uri: auth_uri, state: state }.to_json,
          )
      end

      def stub_account_api_validates_auth_response(code: nil, state: nil, govuk_account_session: "govuk-account-session", redirect_path: "/", ga_client_id: "ga-client-id")
        stub_request(:post, "#{ACCOUNT_API_ENDPOINT}/api/oauth2/callback")
          .with(body: hash_including({ code: code, state: state }.compact))
          .to_return(
            status: 200,
            body: { govuk_account_session: govuk_account_session, redirect_path: redirect_path, ga_client_id: ga_client_id }.to_json,
          )
      end

      def stub_account_api_rejects_auth_response(code: nil, state: nil)
        stub_request(:post, "#{ACCOUNT_API_ENDPOINT}/api/oauth2/callback")
          .with(body: hash_including({ code: code, state: state }.compact))
          .to_return(status: 401)
      end

      def stub_account_api_create_registration_state(attributes: nil, state_id: "state-id")
        stub_request(:post, "#{ACCOUNT_API_ENDPOINT}/api/oauth2/state")
          .with(body: hash_including({ attributes: attributes }.compact))
          .to_return(
            status: 200,
            body: { state_id: state_id }.to_json,
          )
      end

      def stub_account_api_has_email_subscription(govuk_account_session: nil, new_govuk_account_session: nil)
        if govuk_account_session
          stub_request(:get, "#{ACCOUNT_API_ENDPOINT}/api/transition-checker-email-subscription")
            .with(headers: { GdsApi::AccountApi::AUTH_HEADER_NAME => govuk_account_session })
            .to_return(status: 200, body: { govuk_account_session: new_govuk_account_session, has_subscription: true }.compact.to_json)
        else
          stub_request(:get, "#{ACCOUNT_API_ENDPOINT}/api/transition-checker-email-subscription")
            .to_return(status: 200, body: { govuk_account_session: new_govuk_account_session, has_subscription: true }.compact.to_json)
        end
      end

      def stub_account_api_does_not_have_email_subscription(govuk_account_session: nil, new_govuk_account_session: nil)
        if govuk_account_session
          stub_request(:get, "#{ACCOUNT_API_ENDPOINT}/api/transition-checker-email-subscription")
            .with(headers: { GdsApi::AccountApi::AUTH_HEADER_NAME => govuk_account_session })
            .to_return(status: 200, body: { govuk_account_session: new_govuk_account_session, has_subscription: false }.compact.to_json)
        else
          stub_request(:get, "#{ACCOUNT_API_ENDPOINT}/api/transition-checker-email-subscription")
            .to_return(status: 200, body: { govuk_account_session: new_govuk_account_session, has_subscription: false }.compact.to_json)
        end
      end

      def stub_account_api_set_email_subscription(govuk_account_session: nil, slug: "slug", new_govuk_account_session: nil)
        if govuk_account_session
          stub_request(:post, "#{ACCOUNT_API_ENDPOINT}/api/transition-checker-email-subscription")
            .with(body: hash_including({ slug: slug }.compact), headers: { GdsApi::AccountApi::AUTH_HEADER_NAME => govuk_account_session })
            .to_return(status: 200, body: { govuk_account_session: new_govuk_account_session }.compact.to_json)
        else
          stub_request(:post, "#{ACCOUNT_API_ENDPOINT}/api/transition-checker-email-subscription")
            .with(body: hash_including({ slug: slug }.compact))
            .to_return(status: 200, body: { govuk_account_session: new_govuk_account_session }.compact.to_json)
        end
      end

      def stub_account_api_has_attributes(govuk_account_session: nil, attributes: [], values: {}, new_govuk_account_session: nil)
        querystring = Rack::Utils.build_nested_query({ attributes: attributes }.compact)
        if govuk_account_session
          stub_request(:get, "#{ACCOUNT_API_ENDPOINT}/api/attributes?#{querystring}")
            .with(headers: { GdsApi::AccountApi::AUTH_HEADER_NAME => govuk_account_session })
            .to_return(status: 200, body: { govuk_account_session: new_govuk_account_session, values: values }.compact.to_json)
        else
          stub_request(:get, "#{ACCOUNT_API_ENDPOINT}/api/attributes?#{querystring}")
            .to_return(status: 200, body: { govuk_account_session: new_govuk_account_session, values: values }.compact.to_json)
        end
      end

      def stub_account_api_set_attributes(govuk_account_session: nil, attributes: nil, new_govuk_account_session: nil)
        if govuk_account_session
          stub_request(:patch, "#{ACCOUNT_API_ENDPOINT}/api/attributes")
            .with(body: hash_including({ attributes: attributes }.compact), headers: { GdsApi::AccountApi::AUTH_HEADER_NAME => govuk_account_session })
            .to_return(status: 200, body: { govuk_account_session: new_govuk_account_session }.compact.to_json)
        else
          stub_request(:patch, "#{ACCOUNT_API_ENDPOINT}/api/attributes")
            .with(body: hash_including({ attributes: attributes }.compact))
            .to_return(status: 200, body: { govuk_account_session: new_govuk_account_session }.compact.to_json)
        end
      end
    end
  end
end
