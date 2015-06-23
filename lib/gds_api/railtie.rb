require_relative 'middleware/govuk_header_sniffer'

module GdsApi
  class Railtie < Rails::Railtie
    initializer "gds_api.initialize_govuk_request_id_sniffer" do |app|
      Rails.logger.info "Using middleware GdsApi::GovukHeaderSniffer to sniff for GOVUK-Request-Id header"
      app.middleware.use GdsApi::GovukHeaderSniffer, 'HTTP_GOVUK_REQUEST_ID'
    end
  end
end
