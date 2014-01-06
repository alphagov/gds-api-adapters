require_relative '../govuk_request_id'

module GdsApi
  class GovukRequestIdSniffer
    def initialize(app)
      @app = app
    end

    def call(env)
      GdsApi::GovukRequestId.value = env['HTTP_GOVUK_REQUEST_ID']
      @app.call(env)
    end
  end
end
