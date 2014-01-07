require_relative 'middleware/govuk_request_id_sniffer'

module GdsApi
  class Railtie < Rails::Railtie
    initializer "gds_api.initialize_govuk_request_id_sniffer" do |app|
      Rails.logger.info "Using middleware GdsApi::GovukRequestIdSniffer to sniff for GOVUK-Request-Id header"
      app.middleware.use GdsApi::GovukRequestIdSniffer
    end
  end
end
