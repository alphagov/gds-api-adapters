require_relative 'middleware/govuk_header_sniffer'

module GdsApi
  class Railtie < Rails::Railtie
    initializer "gds_api.initialize_govuk_request_id_sniffer" do |app|
      Rails.logger.info "Using middleware GdsApi::GovukHeaderSniffer to sniff for GOVUK-Request-Id header"
      app.middleware.use GdsApi::GovukHeaderSniffer, 'HTTP_GOVUK_REQUEST_ID'
    end

    initializer "gds_api.initialize_govuk_authenticated_user_sniffer" do |app|
      Rails.logger.info "Using middleware GdsApi::GovukHeaderSniffer to sniff for X-GOVUK-Authenticated-User header"
      app.middleware.use GdsApi::GovukHeaderSniffer, 'HTTP_X_GOVUK_AUTHENTICATED_USER'
    end
  end
end
