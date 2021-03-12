require_relative "base"
require_relative "exceptions"

# Adapter for the Account API
#
# @see https://github.com/alphagov/account-api
# @api documented
class GdsApi::AccountApi < GdsApi::Base
  # Get an OAuth sign-in URL to redirect the user to
  #
  # @param [String, nil] redirect_path path on GOV.UK to send the user to after authentication
  # @param [String, nil] state_id identifier originally returned by #create_registration_state
  #
  # @return [Hash] An authentication URL and the OAuth state parameter (for CSRF protection)
  def get_sign_in_url(redirect_path: nil, state_id: nil)
    querystring = nested_query_string({ redirect_path: redirect_path, state_id: state_id }.compact)
    get_json("#{endpoint}/api/oauth2/sign-in?#{querystring}")
  end

  # Validate an OAuth authentication response
  #
  # @param [String] code The OAuth code parameter, from the auth server.
  # @param [String] state The OAuth state parameter, from the auth server.
  #
  # @return [Hash] The value for the govuk_account_session header, the path to redirect the user to, and the GA client ID (if there is one)
  def validate_auth_response(code:, state:)
    post_json("#{endpoint}/api/oauth2/callback", code: code, state: state)
  end

  # Register some initial state, to pass to get_sign_in_url, which is used to initialise the account if the user signs up
  #
  # @param [Hash, nil] attributes Initial attributes to store
  #
  # @return [Hash] The state ID to pass to get_sign_in_url
  def create_registration_state(attributes:)
    post_json("#{endpoint}/api/oauth2/state", attributes: attributes)
  end

private

  def nested_query_string(params)
    Rack::Utils.build_nested_query(params)
  end
end
