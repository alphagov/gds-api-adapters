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
  # @param [String, nil] level_of_authentication either "level1" (require MFA) or "level0" (do not require MFA)
  #
  # @return [Hash] An authentication URL and the OAuth state parameter (for CSRF protection)
  def get_sign_in_url(redirect_path: nil, level_of_authentication: nil)
    querystring = nested_query_string(
      {
        redirect_path: redirect_path,
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

  # Get all the information about a user needed to render the account home page
  #
  # @param [String] govuk_account_session Value of the session header
  #
  # @return [Hash] Information about the user and the services they've used, and a new session header
  def get_user(govuk_account_session:)
    get_json("#{endpoint}/api/user", auth_headers(govuk_account_session))
  end

  # Update the user record with privileged information from the auth service.  Only the auth service will call this.
  #
  # @param [String] subject_identifier The identifier of the user, shared between the auth service and GOV.UK.
  # @param [String, nil] email The user's current
  # @param [Boolean, nil] email_verified Whether the user's current email address is verified
  # @param [Boolean, nil] has_unconfirmed_email Whether the user has a new, pending, email address
  #
  # @return [Hash] The user's subject identifier and email attributes
  def update_user_by_subject_identifier(subject_identifier:, email: nil, email_verified: nil, has_unconfirmed_email: nil)
    params = {
      email: email,
      email_verified: email_verified,
      has_unconfirmed_email: has_unconfirmed_email,
    }.compact

    patch_json("#{endpoint}/api/oidc-users/#{subject_identifier}", params)
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

  # Get the details of an account-linked email subscription.
  #
  # @param [String] name Name of the subscription
  # @param [String] govuk_account_session Value of the session header
  #
  # @return [Hash] Details of the subscription, if it exists.
  def get_email_subscription(name:, govuk_account_session:)
    get_json("#{endpoint}/api/email-subscriptions/#{CGI.escape(name)}", auth_headers(govuk_account_session))
  end

  # Create or update an account-linked email subscription.
  #
  # @param [String] name Name of the subscription
  # @param [String] topic_slug The email-alert-api topic slug to subscribe to
  # @param [String] govuk_account_session Value of the session header
  #
  # @return [Hash] Details of the newly created subscription.
  def put_email_subscription(name:, topic_slug:, govuk_account_session:)
    put_json("#{endpoint}/api/email-subscriptions/#{CGI.escape(name)}", { topic_slug: topic_slug }, auth_headers(govuk_account_session))
  end

  # Unsubscribe and delete an account-linked email subscription.
  #
  # @param [String] name Name of the subscription
  # @param [String] govuk_account_session Value of the session header
  def delete_email_subscription(name:, govuk_account_session:)
    delete_json("#{endpoint}/api/email-subscriptions/#{CGI.escape(name)}", {}, auth_headers(govuk_account_session))
  end

  # Look up all pages saved by a user in their Account
  #
  # @param [String] govuk_account_session Value of the session header
  #
  # @return [Hash] containing :saved_pages, an array of single saved page hashes
  def get_saved_pages(govuk_account_session:)
    get_json("#{endpoint}/api/saved-pages", auth_headers(govuk_account_session))
  end

  # Return a single page by unique URL
  #
  # @param [String] the path of a page to check
  # @param [String] govuk_account_session Value of the session header
  #
  # @return [Hash] containing :saved_page, a hash of a single saved page value
  def get_saved_page(page_path:, govuk_account_session:)
    get_json("#{endpoint}/api/saved-pages/#{CGI.escape(page_path)}", auth_headers(govuk_account_session))
  end

  # Upsert a single saved page entry in a users account
  #
  # @param [String] the path of a page to check
  # @param [String] govuk_account_session Value of the session header
  #
  # @return [Hash] A single saved page value (if sucessful)
  def save_page(page_path:, govuk_account_session:)
    put_json("#{endpoint}/api/saved-pages/#{CGI.escape(page_path)}", {}, auth_headers(govuk_account_session))
  end

  # Delete a single saved page entry from a users account
  #
  # @param [String] the path of a page to check
  # @param [String] govuk_account_session Value of the session header
  #
  # @return [GdsApi::Response] A status code of 204 indicates the saved page has been successfully deleted.
  #                            A status code of 404 indicates there is no saved page with this path.
  def delete_saved_page(page_path:, govuk_account_session:)
    delete_json("#{endpoint}/api/saved-pages/#{CGI.escape(page_path)}", {}, auth_headers(govuk_account_session))
  end

private

  def nested_query_string(params)
    Rack::Utils.build_nested_query(params)
  end

  def auth_headers(govuk_account_session)
    { AUTH_HEADER_NAME => govuk_account_session }
  end
end
