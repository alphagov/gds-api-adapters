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
    end
  end
end
