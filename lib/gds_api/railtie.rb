require_relative "middleware/govuk_header_sniffer"

module GdsApi
  class Railtie < Rails::Railtie
    initializer "gds_api.initialize_govuk_request_id_sniffer" do |app|
      Rails.logger.debug "Using middleware GdsApi::GovukHeaderSniffer to sniff for Govuk-Request-Id header"
      app.middleware.use GdsApi::GovukHeaderSniffer, "HTTP_GOVUK_REQUEST_ID"
    end

    initializer "gds_api.initialize_govuk_original_url_sniffer" do |app|
      Rails.logger.debug "Using middleware GdsApi::GovukHeaderSniffer to sniff for Govuk-Original-Url header"
      app.middleware.use GdsApi::GovukHeaderSniffer, "HTTP_GOVUK_ORIGINAL_URL"
    end

    initializer "gds_api.initialize_govuk_authenticated_user_sniffer" do |app|
      Rails.logger.debug "Using middleware GdsApi::GovukHeaderSniffer to sniff for X-Govuk-Authenticated-User header"
      app.middleware.use GdsApi::GovukHeaderSniffer, "HTTP_X_GOVUK_AUTHENTICATED_USER"
    end

    initializer "gds_api.initialize_govuk_authenticated_user_organisation_sniffer" do |app|
      Rails.logger.debug "Using middleware GdsApi::GovukHeaderSniffer to sniff for X-Govuk-Authenticated-User-Organisation header"
      app.middleware.use GdsApi::GovukHeaderSniffer, "HTTP_X_GOVUK_AUTHENTICATED_USER_ORGANISATION"
    end

    initializer "gds_api.initialize_govuk_content_id_sniffer" do |app|
      Rails.logger.debug "Using middleware GdsApi::GovukHeaderSniffer to sniff for Govuk-Auth-Bypass-Id header"
      app.middleware.use GdsApi::GovukHeaderSniffer, "HTTP_GOVUK_AUTH_BYPASS_ID"
    end
  end
end
