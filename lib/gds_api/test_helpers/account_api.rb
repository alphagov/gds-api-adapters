require "json"

module GdsApi
  module TestHelpers
    module AccountApi
      ACCOUNT_API_ENDPOINT = Plek.find("account-api")

      def stub_account_api_request(method, path, with: {}, response_status: 200, response_body: {}, govuk_account_session: nil, new_govuk_account_session: nil)
        with.merge!(headers: { GdsApi::AccountApi::AUTH_HEADER_NAME => govuk_account_session }) if govuk_account_session
        new_govuk_account_session = nil if response_status >= 400
        to_return = { status: response_status, body: response_body.merge(govuk_account_session: new_govuk_account_session).compact.to_json }
        if with.empty?
          stub_request(method, "#{ACCOUNT_API_ENDPOINT}#{path}").to_return(**to_return)
        else
          stub_request(method, "#{ACCOUNT_API_ENDPOINT}#{path}").with(**with).to_return(**to_return)
        end
      end

      #########################
      # GET /api/oauth2/sign-in
      #########################
      def stub_account_api_get_sign_in_url(redirect_path: nil, mfa: false, auth_uri: "http://auth/provider", state: "state")
        querystring = Rack::Utils.build_nested_query({ redirect_path: redirect_path, mfa: mfa }.compact)
        stub_request(:get, "#{ACCOUNT_API_ENDPOINT}/api/oauth2/sign-in?#{querystring}")
          .to_return(
            status: 200,
            body: { auth_uri: auth_uri, state: state }.to_json,
          )
      end

      ###########################
      # POST /api/oauth2/callback
      ###########################
      def stub_account_api_validates_auth_response(code: nil, state: nil, govuk_account_session: "govuk-account-session", redirect_path: "/", ga_client_id: "ga-client-id", cookie_consent: false, feedback_consent: false)
        stub_request(:post, "#{ACCOUNT_API_ENDPOINT}/api/oauth2/callback")
          .with(body: hash_including({ code: code, state: state }.compact))
          .to_return(
            status: 200,
            body: { govuk_account_session: govuk_account_session, redirect_path: redirect_path, ga_client_id: ga_client_id, cookie_consent: cookie_consent, feedback_consent: feedback_consent }.to_json,
          )
      end

      def stub_account_api_rejects_auth_response(code: nil, state: nil)
        stub_request(:post, "#{ACCOUNT_API_ENDPOINT}/api/oauth2/callback")
          .with(body: hash_including({ code: code, state: state }.compact))
          .to_return(status: 401)
      end

      #############################
      # GET /api/oauth2/end-session
      #############################
      def stub_account_api_get_end_session_url(govuk_account_session: nil, end_session_uri: "http://auth/provider")
        if govuk_account_session
          stub_request(:get, "#{ACCOUNT_API_ENDPOINT}/api/oauth2/end-session")
            .with(headers: { GdsApi::AccountApi::AUTH_HEADER_NAME => govuk_account_session })
            .to_return(
              status: 200,
              body: { end_session_uri: end_session_uri }.to_json,
            )
        else
          stub_request(:get, "#{ACCOUNT_API_ENDPOINT}/api/oauth2/end-session")
            .to_return(
              status: 200,
              body: { end_session_uri: end_session_uri }.to_json,
            )
        end
      end

      ###############
      # GET /api/user
      ###############
      def stub_account_api_user_info(id: "user-id", mfa: false, email: "email@example.com", email_verified: true, services: {}, **options)
        stub_account_api_request(
          :get,
          "/api/user",
          response_body: {
            id: id,
            mfa: mfa,
            email: email,
            email_verified: email_verified,
            services: services,
          },
          **options,
        )
      end

      def stub_account_api_user_info_service_state(service:, service_state: "yes", **options)
        stub_account_api_user_info(
          **options.merge(
            services: options.fetch(:services, {}).merge(service => service_state),
          ),
        )
      end

      def stub_account_api_unauthorized_user_info(**options)
        stub_account_api_request(
          :get,
          "/api/user",
          response_status: 401,
          **options,
        )
      end

      ##############################
      # GET /api/user/match-by-email
      ##############################

      def stub_account_api_match_user_by_email_matches(email:, **options)
        stub_account_api_request(
          :get,
          "/api/user/match-by-email?#{Rack::Utils.build_nested_query({ email: email })}",
          response_body: {
            match: true,
          },
          **options,
        )
      end

      def stub_account_api_match_user_by_email_does_not_match(email:, **options)
        stub_account_api_request(
          :get,
          "/api/user/match-by-email?#{Rack::Utils.build_nested_query({ email: email })}",
          response_body: {
            match: false,
          },
          **options,
        )
      end

      def stub_account_api_match_user_by_email_does_not_exist(email:, **options)
        stub_account_api_request(
          :get,
          "/api/user/match-by-email?#{Rack::Utils.build_nested_query({ email: email })}",
          response_status: 404,
          **options,
        )
      end

      ############################################
      # DELETE /api/oidc-users/:subject_identifier
      ############################################

      def stub_account_api_delete_user_by_subject_identifier(subject_identifier:)
        stub_account_api_request(
          :delete,
          "/api/oidc-users/#{subject_identifier}",
          response_status: 204,
        )
      end

      def stub_account_api_delete_user_by_subject_identifier_does_not_exist(subject_identifier:)
        stub_account_api_request(
          :delete,
          "/api/oidc-users/#{subject_identifier}",
          response_status: 404,
        )
      end

      ###########################################
      # PATCH /api/oidc-users/:subject_identifier
      ###########################################
      def stub_update_user_by_subject_identifier(subject_identifier:, email: nil, email_verified: nil, old_email: nil, old_email_verified: nil)
        stub_account_api_request(
          :patch,
          "/api/oidc-users/#{subject_identifier}",
          with: { body: hash_including({ email: email, email_verified: email_verified }.compact) },
          response_body: {
            sub: subject_identifier,
            email: email || old_email,
            email_verified: email_verified || old_email_verified,
          },
        )
      end

      #####################
      # GET /api/attributes
      #####################
      def stub_account_api_has_attributes(attributes: [], values: {}, **options)
        querystring = Rack::Utils.build_nested_query({ attributes: attributes }.compact)
        stub_account_api_request(
          :get,
          "/api/attributes?#{querystring}",
          response_body: { values: values },
          **options,
        )
      end

      def stub_account_api_unauthorized_has_attributes(attributes: [], **options)
        querystring = Rack::Utils.build_nested_query({ attributes: attributes }.compact)
        stub_account_api_request(
          :get,
          "/api/attributes?#{querystring}",
          response_status: 401,
          **options,
        )
      end

      def stub_account_api_forbidden_has_attributes(attributes: [], **options)
        querystring = Rack::Utils.build_nested_query({ attributes: attributes }.compact)
        stub_account_api_request(
          :get,
          "/api/attributes?#{querystring}",
          response_status: 403,
          **options,
        )
      end

      #######################
      # PATCH /api/attributes
      #######################
      def stub_account_api_set_attributes(attributes: nil, **options)
        stub_account_api_request(
          :patch,
          "/api/attributes",
          with: { body: hash_including({ attributes: attributes }.compact) },
          **options,
        )
      end

      def stub_account_api_unauthorized_set_attributes(attributes: nil, **options)
        stub_account_api_request(
          :patch,
          "/api/attributes",
          with: { body: hash_including({ attributes: attributes }.compact) },
          response_status: 401,
          **options,
        )
      end

      def stub_account_api_forbidden_set_attributes(attributes: nil, **options)
        stub_account_api_request(
          :patch,
          "/api/attributes",
          with: { body: hash_including({ attributes: attributes }.compact) },
          response_status: 403,
          **options,
        )
      end
    end
  end
end
