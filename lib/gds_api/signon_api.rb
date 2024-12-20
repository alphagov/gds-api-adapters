require_relative "base"

class GdsApi::SignonApi < GdsApi::Base
  # Get users with specific UUIDs
  #
  # @param uuids [Array]
  #
  #  signon_api.users(
  #     ["7ac47b33-c09c-4c1d-a9a7-0cfef99081ac"],
  #  )
  #
  # @return [GdsApi::Response] A response containing a list of users with the specified UUIDs
  def get_users(uuids:)
    query = query_string(uuids:)
    get_json("#{endpoint}/api/users#{query}")
  end
end
