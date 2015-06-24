require_relative '../govuk_headers'

module GdsApi
  class GovukHeaderSniffer
    def initialize(app, header_name)
      @app = app
      @header_name = header_name
    end

    def call(env)
      GdsApi::GovukHeaders.set_header(readable_name, env[@header_name])
      @app.call(env)
    end

    private

    def readable_name
      @header_name.sub(/^HTTP_/, "").downcase.to_sym
    end
  end
end
