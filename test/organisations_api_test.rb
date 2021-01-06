require_relative "test_helper"
require "gds_api/organisations"
require "gds_api/test_helpers/organisations"

describe GdsApi::Organisations do
  include GdsApi::TestHelpers::Organisations
  include PactTest
  
end
