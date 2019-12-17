require_relative "publishing_api"

# Adapter for the Publishing API.
#
# @see https://github.com/alphagov/publishing-api
# @see https://github.com/alphagov/publishing-api/blob/master/doc/publishing-application-examples.md
# @see https://github.com/alphagov/publishing-api/blob/master/doc/model.md
# @api documented
class GdsApi::PublishingApiV2 < GdsApi::PublishingApi
  def initialize(*args)
    warn "GdsApi::PublishingApiV2 is deprecated.  Use GdsApi::PublishingApi instead."
    super
  end
end
