require_relative "base"
require_relative "exceptions"

# Adapter for the Account API
#
# @see https://github.com/alphagov/account-api
# @api documented
class GdsApi::AccountApi < GdsApi::Base
  AUTH_HEADER_NAME = "GOVUK-Account-Session".freeze

  # Get an OAuth sign-in URL to redirect the user to
  #
  # @param [String, nil] redirect_path path on GOV.UK to send the user to after authentication
  # @param [String, nil] state_id identifier originally returned by #create_registration_state
  # @param [String, nil] level_of_authentication either "level1" (require MFA) or "level0" (do not require MFA)
  #
  # @return [Hash] An authentication URL and the OAuth state parameter (for CSRF protection)
  def get_sign_in_url(redirect_path: nil, state_id: nil, level_of_authentication: nil)
    querystring = nested_query_string(
      {
        redirect_path: redirect_path,
        state_id: state_id,
        level_of_authentication: level_of_authentication,
      }.compact,
    )
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

  # Check if a user has an email subscription for the Transition Checker
  #
  # @param [String] govuk_account_session Value of the session header
  #
  # @return [Hash] Whether the user has a subscription, and a new session header
  def check_for_email_subscription(govuk_account_session:)
    get_json("#{endpoint}/api/transition-checker-email-subscription", auth_headers(govuk_account_session))
  end

  # Create or update a user's email subscription for the Transition Checker
  #
  # @param [String] govuk_account_session Value of the session header
  # @param [String] slug The email topic slug
  #
  # @return [Hash] Whether the user has a subscription, and a new session header
  def set_email_subscription(govuk_account_session:, slug:)
    post_json("#{endpoint}/api/transition-checker-email-subscription", { slug: slug }, auth_headers(govuk_account_session))
  end

  # Look up the values of a user's attributes
  #
  # @param [String] attributes Names of the attributes to check
  # @param [String] govuk_account_session Value of the session header
  #
  # @return [Hash] The attribute values (if present), and a new session header
  def get_attributes(attributes:, govuk_account_session:)
    querystring = nested_query_string({ attributes: attributes }.compact)
    get_json("#{endpoint}/api/attributes?#{querystring}", auth_headers(govuk_account_session))
  end

  # Create or update attributes for a user
  #
  # @param [String] attributes Hash of new attribute values
  # @param [String] govuk_account_session Value of the session header
  #
  # @return [Hash] A new session header
  def set_attributes(attributes:, govuk_account_session:)
    patch_json("#{endpoint}/api/attributes", { attributes: attributes }, auth_headers(govuk_account_session))
  end

  # Look up the names of a user's attributes
  #
  # @param [String] attributes Names of the attributes to check
  # @param [String] govuk_account_session Value of the session header
  #
  # @return [Hash] The attribute names (if present), and a new session header
  def get_attributes_names(attributes:, govuk_account_session:)
    querystring = nested_query_string({ attributes: attributes }.compact)
    get_json("#{endpoint}/api/attributes/names?#{querystring}", auth_headers(govuk_account_session))
  end

  # Look up all pages saved by a user in their Account
  #
  # @param [String] govuk_account_session Value of the session header
  #
  # @return [Hash] containing :saved_pages, an array of single saved page hashes  def get_saved_pages(govuk_account_session:)
  def get_saved_pages(govuk_account_session:)
    get_json("#{endpoint}/api/saved_pages", auth_headers(govuk_account_session))
  end

  # Return a single page by unique URL
  #
  # @param [String] the path of a page to check
  # @param [String] govuk_account_session Value of the session header
  #
  # @return [Hash] containing :saved_page, a hash of a single saved page value
  def get_saved_page(page_path:, govuk_account_session:)
    get_json("#{endpoint}/api/saved_pages/#{CGI.escape(page_path)}", auth_headers(govuk_account_session))
  end

  # Upsert a single saved page entry in a users account
  #
  # @param [String] the path of a page to check
  # @param [String] govuk_account_session Value of the session header
  #
  # @return [Hash] A single saved page value (if sucessful)
  def save_page(page_path:, govuk_account_session:)
    put_json("#{endpoint}/api/saved_pages/#{CGI.escape(page_path)}", {}, auth_headers(govuk_account_session))
  end

  # Delete a single saved page entry from a users account
  #
  # @param [String] the path of a page to check
  # @param [String] govuk_account_session Value of the session header
  #
  # @return [GdsApi::Response] A status code of 204 indicates the saved page has been successfully deleted.
  #                            A status code of 404 indicates there is no saved page with this path.
  def delete_saved_page(page_path:, govuk_account_session:)
    delete_json("#{endpoint}/api/saved_pages/#{CGI.escape(page_path)}", {}, auth_headers(govuk_account_session))
  end

private

  def nested_query_string(params)
    Rack::Utils.build_nested_query(params)
  end

  def auth_headers(govuk_account_session)
    { AUTH_HEADER_NAME => govuk_account_session }
  end
end
