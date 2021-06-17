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
      def stub_account_api_get_sign_in_url(redirect_path: nil, state_id: nil, level_of_authentication: nil, auth_uri: "http://auth/provider", state: "state")
        querystring = Rack::Utils.build_nested_query({ redirect_path: redirect_path, state_id: state_id, level_of_authentication: level_of_authentication }.compact)
        stub_request(:get, "#{ACCOUNT_API_ENDPOINT}/api/oauth2/sign-in?#{querystring}")
          .to_return(
            status: 200,
            body: { auth_uri: auth_uri, state: state }.to_json,
          )
      end

      ###########################
      # POST /api/oauth2/callback
      ###########################
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

      ########################
      # POST /api/oauth2/state
      ########################
      def stub_account_api_create_registration_state(attributes: nil, state_id: "state-id")
        stub_request(:post, "#{ACCOUNT_API_ENDPOINT}/api/oauth2/state")
          .with(body: hash_including({ attributes: attributes }.compact))
          .to_return(
            status: 200,
            body: { state_id: state_id }.to_json,
          )
      end

      ###############
      # GET /api/user
      ###############
      def stub_account_api_user_info(level_of_authentication: "level0", email: "email@example.com", email_verified: true, has_unconfirmed_email: false, services: {}, **options)
        stub_account_api_request(
          :get,
          "/api/user",
          response_body: {
            level_of_authentication: level_of_authentication,
            email: email,
            email_verified: email_verified,
            has_unconfirmed_email: has_unconfirmed_email,
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

      ###########################################
      # PATCH /api/oidc-users/:subject_identifier
      ###########################################
      def stub_update_user_by_subject_identifier(subject_identifier:, email: nil, email_verified: nil, has_unconfirmed_email: nil, old_email: nil, old_email_verified: nil, old_has_unconfirmed_email: nil)
        stub_account_api_request(
          :patch,
          "/api/oidc-users/#{subject_identifier}",
          with: { body: hash_including({ email: email, email_verified: email_verified, has_unconfirmed_email: has_unconfirmed_email }.compact) },
          response_body: {
            sub: subject_identifier,
            email: email || old_email,
            email_verified: email_verified || old_email_verified,
            has_unconfirmed_email: has_unconfirmed_email || old_has_unconfirmed_email,
          },
        )
      end

      ####################################
      # GET /api/email-subscriptions/:name
      ####################################
      def stub_account_api_get_email_subscription(name:, topic_slug: "slug", email_alert_api_subscription_id: "12345", **options)
        stub_account_api_request(
          :get,
          "/api/email-subscriptions/#{name}",
          response_body: {
            email_subscription: {
              name: name,
              topic_slug: topic_slug,
              email_alert_api_subscription_id: email_alert_api_subscription_id,
            },
          },
          **options,
        )
      end

      def stub_account_api_get_email_subscription_does_not_exist(name:, **options)
        stub_account_api_request(
          :get,
          "/api/email-subscriptions/#{name}",
          response_status: 404,
          **options,
        )
      end

      def stub_account_api_get_email_subscription_unauthorized(name:, **options)
        stub_account_api_request(
          :get,
          "/api/email-subscriptions/#{name}",
          response_status: 401,
          **options,
        )
      end

      ####################################
      # PUT /api/email-subscriptions/:name
      ####################################
      def stub_account_api_put_email_subscription(name:, topic_slug: nil, **options)
        stub_account_api_request(
          :put,
          "/api/email-subscriptions/#{name}",
          with: { body: hash_including({ topic_slug: topic_slug }.compact) },
          response_body: {
            email_subscription: {
              name: name,
              topic_slug: topic_slug || "slug",
            },
          },
          **options,
        )
      end

      def stub_account_api_unauthorized_put_email_subscription(name:, topic_slug: nil, **options)
        stub_account_api_request(
          :put,
          "/api/email-subscriptions/#{name}",
          with: { body: hash_including({ topic_slug: topic_slug }.compact) },
          response_status: 401,
          **options,
        )
      end

      #######################################
      # DELETE /api/email-subscriptions/:name
      #######################################
      def stub_account_api_delete_email_subscription(name:, **options)
        stub_account_api_request(
          :delete,
          "/api/email-subscriptions/#{name}",
          response_status: 204,
          **options,
        )
      end

      def stub_account_api_delete_email_subscription_does_not_exist(name:, **options)
        stub_account_api_request(
          :delete,
          "/api/email-subscriptions/#{name}",
          response_status: 404,
          **options,
        )
      end

      def stub_account_api_unauthorized_delete_email_subscription(name:, **options)
        stub_account_api_request(
          :delete,
          "/api/email-subscriptions/#{name}",
          response_status: 401,
          **options,
        )
      end

      ################################################
      # GET /api/transition-checker-email-subscription
      ################################################
      def stub_account_api_has_email_subscription(**options)
        stub_account_api_request(
          :get,
          "/api/transition-checker-email-subscription",
          response_body: { has_subscription: true },
          **options,
        )
      end

      def stub_account_api_does_not_have_email_subscription(**options)
        stub_account_api_request(
          :get,
          "/api/transition-checker-email-subscription",
          response_body: { has_subscription: false },
          **options,
        )
      end

      def stub_account_api_unauthorized_get_email_subscription(**options)
        stub_account_api_request(
          :get,
          "/api/transition-checker-email-subscription",
          response_status: 401,
          **options,
        )
      end

      def stub_account_api_forbidden_get_email_subscription(needed_level_of_authentication: "level1", **options)
        stub_account_api_request(
          :get,
          "/api/transition-checker-email-subscription",
          response_status: 403,
          response_body: { needed_level_of_authentication: needed_level_of_authentication },
          **options,
        )
      end

      #################################################
      # POST /api/transition-checker-email-subscription
      #################################################
      def stub_account_api_set_email_subscription(slug: nil, **options)
        stub_account_api_request(
          :post,
          "/api/transition-checker-email-subscription",
          with: { body: hash_including({ slug: slug }.compact) },
          **options,
        )
      end

      def stub_account_api_unauthorized_set_email_subscription(slug: nil, **options)
        stub_account_api_request(
          :post,
          "/api/transition-checker-email-subscription",
          with: { body: hash_including({ slug: slug }.compact) },
          response_status: 401,
          **options,
        )
      end

      def stub_account_api_forbidden_set_email_subscription(slug: nil, needed_level_of_authentication: "level1", **options)
        stub_account_api_request(
          :post,
          "/api/transition-checker-email-subscription",
          with: { body: hash_including({ slug: slug }.compact) },
          response_status: 403,
          response_body: { needed_level_of_authentication: needed_level_of_authentication },
          **options,
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

      def stub_account_api_forbidden_has_attributes(attributes: [], needed_level_of_authentication: "level1", **options)
        querystring = Rack::Utils.build_nested_query({ attributes: attributes }.compact)
        stub_account_api_request(
          :get,
          "/api/attributes?#{querystring}",
          response_status: 403,
          response_body: { needed_level_of_authentication: needed_level_of_authentication },
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

      def stub_account_api_forbidden_set_attributes(attributes: nil, needed_level_of_authentication: "level1", **options)
        stub_account_api_request(
          :patch,
          "/api/attributes",
          with: { body: hash_including({ attributes: attributes }.compact) },
          response_status: 403,
          response_body: { needed_level_of_authentication: needed_level_of_authentication },
          **options,
        )
      end

      ###########################
      # GET /api/attributes/names
      ###########################
      def stub_account_api_get_attributes_names(attributes: [], **options)
        querystring = Rack::Utils.build_nested_query({ attributes: attributes }.compact)
        stub_account_api_request(
          :get,
          "/api/attributes/names?#{querystring}",
          response_body: { values: attributes },
          **options,
        )
      end

      def stub_account_api_unauthorized_get_attributes_names(attributes: [], **options)
        querystring = Rack::Utils.build_nested_query({ attributes: attributes }.compact)
        stub_account_api_request(
          :get,
          "/api/attributes/names?#{querystring}",
          response_status: 401,
          **options,
        )
      end

      def stub_account_api_forbidden_get_attributes_names(attributes: [], needed_level_of_authentication: "level1", **options)
        querystring = Rack::Utils.build_nested_query({ attributes: attributes }.compact)
        stub_account_api_request(
          :get,
          "/api/attributes/names?#{querystring}",
          response_status: 403,
          response_body: { needed_level_of_authentication: needed_level_of_authentication },
          **options,
        )
      end

      ######################
      # GET /api/saved-pages
      ######################
      def stub_account_api_returning_saved_pages(saved_pages: [], **options)
        stub_account_api_request(
          :get,
          "/api/saved-pages",
          response_body: { saved_pages: saved_pages },
          **options,
        )
      end

      def stub_account_api_unauthorized_get_saved_pages(**options)
        stub_account_api_request(
          :get,
          "/api/saved-pages",
          response_status: 401,
          **options,
        )
      end

      #################################
      # GET /api/saved_pages/:page_path
      #################################
      def stub_account_api_get_saved_page(page_path:, content_id: "46163ed2-1777-4ee6-bdd4-6a2007e49d8f", title: "Ministry of Magic", **options)
        stub_account_api_request(
          :get,
          "/api/saved-pages/#{CGI.escape(page_path)}",
          response_body: {
            saved_page: {
              page_path: page_path,
              content_id: content_id,
              title: title,
            },
          },
          **options,
        )
      end

      def stub_account_api_does_not_have_saved_page(page_path:, **options)
        stub_account_api_request(
          :get,
          "/api/saved-pages/#{CGI.escape(page_path)}",
          response_status: 404,
          **options,
        )
      end

      def stub_account_api_unauthorized_get_saved_page(page_path:, **options)
        stub_account_api_request(
          :get,
          "/api/saved-pages/#{CGI.escape(page_path)}",
          response_status: 401,
          **options,
        )
      end

      #################################
      # PUT /api/saved-pages/:page_path
      #################################
      def stub_account_api_save_page(page_path:, content_id: "c840bfa2-011a-42cc-ac7a-a6da990aff0b", title: "Ministry of Magic", **options)
        stub_account_api_request(
          :put,
          "/api/saved-pages/#{CGI.escape(page_path)}",
          response_body: {
            saved_page: {
              page_path: page_path,
              content_id: content_id,
              title: title,
            },
          },
          **options,
        )
      end

      def stub_account_api_save_page_already_exists(page_path:, **options)
        stub_account_api_save_page(page_path: page_path, **options)
      end

      def stub_account_api_save_page_cannot_save_page(page_path:, **options)
        stub_account_api_request(
          :put,
          "/api/saved-pages/#{CGI.escape(page_path)}",
          response_status: 422,
          response_body: cannot_save_page_problem_detail({ page_path: page_path }),
          **options,
        )
      end

      def stub_account_api_unauthorized_save_page(page_path:, **options)
        stub_account_api_request(
          :put,
          "/api/saved-pages/#{CGI.escape(page_path)}",
          response_status: 401,
          **options,
        )
      end

      def cannot_save_page_problem_detail(option = {})
        {
          title: "Cannot save page",
          detail: "Cannot save page with path #{option['page_path']}, check it is not blank, and is a well formatted url path.",
          type: "https://github.com/alphagov/account-api/blob/main/docs/api.md#cannot-save-page",
          **option,
        }
      end

      ####################################
      # DELETE /api/saved-pages/:page_path
      ####################################
      def stub_account_api_delete_saved_page(page_path:, **options)
        stub_account_api_request(
          :delete,
          "/api/saved-pages/#{CGI.escape(page_path)}",
          response_status: 204,
          **options,
        )
      end

      def stub_account_api_delete_saved_page_does_not_exist(page_path:, **options)
        stub_account_api_request(
          :delete,
          "/api/saved-pages/#{CGI.escape(page_path)}",
          response_status: 404,
          **options,
        )
      end

      def stub_account_api_delete_saved_page_unauthorised(page_path:, **options)
        stub_account_api_request(
          :delete,
          "/api/saved-pages/#{CGI.escape(page_path)}",
          response_status: 401,
          **options,
        )
      end
    end
  end
end
