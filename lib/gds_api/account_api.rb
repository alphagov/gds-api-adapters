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
  # @param [Boolean, nil] mfa whether to authenticate the user with MFA or not
  #
  # @return [Hash] An authentication URL and the OAuth state parameter (for CSRF protection)
  def get_sign_in_url(redirect_path: nil, mfa: false)
    querystring = nested_query_string(
      {
        redirect_path: redirect_path,
        mfa: mfa,
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

  # Get an OIDC end-session URL to redirect the user to
  #
  # @param [String, nil] govuk_account_session Value of the session header
  #
  # @return [Hash] An end-session URL
  def get_end_session_url(govuk_account_session: nil)
    get_json("#{endpoint}/api/oauth2/end-session", auth_headers(govuk_account_session))
  end

  # Get all the information about a user needed to render the account home page
  #
  # @param [String] govuk_account_session Value of the session header
  #
  # @return [Hash] Information about the user and the services they've used, and a new session header
  def get_user(govuk_account_session:)
    get_json("#{endpoint}/api/user", auth_headers(govuk_account_session))
  end

  # Find a user by email address, returning whether they match the given session (if any)
  #
  # @param [String] email The email address to search for
  # @param [String, nil] govuk_account_session Value of the session header, if not given just checks if the given email address exists.
  #
  # @return [Hash] One field, "match", indicating whether the session matches the given email address
  def match_user_by_email(email:, govuk_account_session: nil)
    querystring = nested_query_string({ email: email })
    get_json("#{endpoint}/api/user/match-by-email?#{querystring}", auth_headers(govuk_account_session))
  end

  # Delete a users account
  #
  # @param [String] subject_identifier The identifier of the user, shared between the auth service and GOV.UK.
  def delete_user_by_subject_identifier(subject_identifier:)
    delete_json("#{endpoint}/api/oidc-users/#{subject_identifier}")
  end

  # Update the user record with privileged information from the auth service.  Only the auth service will call this.
  #
  # @param [String] subject_identifier The identifier of the user, shared between the auth service and GOV.UK.
  # @param [String, nil] email The user's current email address
  # @param [Boolean, nil] email_verified Whether the user's current email address is verified
  #
  # @return [Hash] The user's subject identifier and email attributes
  def update_user_by_subject_identifier(subject_identifier:, email: nil, email_verified: nil)
    params = {
      email: email,
      email_verified: email_verified,
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

private

  def nested_query_string(params)
    Rack::Utils.build_nested_query(params)
  end

  def auth_headers(govuk_account_session)
    { AUTH_HEADER_NAME => govuk_account_session }.compact
  end
end
