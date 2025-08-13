require "addressable"
require "plek"
require "time"
require "gds_api/account_api"
require "gds_api/asset_manager"
require "gds_api/calendars"
require "gds_api/content_store"
require "gds_api/email_alert_api"
require "gds_api/places_manager"
require "gds_api/licence_application"
require "gds_api/link_checker_api"
require "gds_api/local_links_manager"
require "gds_api/locations_api"
require "gds_api/organisations"
require "gds_api/publishing_api"
require "gds_api/search"
require "gds_api/search_api_v2"
require "gds_api/signon_api"
require "gds_api/support"
require "gds_api/support_api"
require "gds_api/worldwide"

# @api documented
module GdsApi
  # Creates a GdsApi::AccountApi adapter
  #
  # This will set a bearer token if a ACCOUNT_API_BEARER_TOKEN environment
  # variable is set
  #
  # @return [GdsApi::AccountApi]
  def self.account_api(options = {})
    GdsApi::AccountApi.new(
      Plek.find("account-api"),
      { bearer_token: ENV["ACCOUNT_API_BEARER_TOKEN"] }.merge(options),
    )
  end

  # Creates a GdsApi::AssetManager adapter
  #
  # This will set a bearer token if a ASSET_MANAGER_BEARER_TOKEN environment
  # variable is set
  #
  # @return [GdsApi::AssetManager]
  def self.asset_manager(options = {})
    GdsApi::AssetManager.new(
      Plek.find("asset-manager"),
      { bearer_token: ENV["ASSET_MANAGER_BEARER_TOKEN"] }.merge(options),
    )
  end

  # Creates a GdsApi::Calendars adapter
  #
  # @return [GdsApi::Calendars]
  def self.calendars(options = {})
    GdsApi::Calendars.new(Plek.new.website_root, options)
  end

  # Creates a GdsApi::ContentStore adapter
  #
  # This will set a bearer token if a CONTENT_STORE_BEARER_TOKEN environment
  # variable is set
  #
  # @return [GdsApi::ContentStore]
  def self.content_store(options = {})
    GdsApi::ContentStore.new(
      Plek.find("content-store"),
      { bearer_token: ENV["CONTENT_STORE_BEARER_TOKEN"] }.merge(options),
    )
  end

  # Creates a GdsApi::EmailAlertApi adapter
  #
  # This will set a bearer token if a EMAIL_ALERT_API_BEARER_TOKEN environment
  # variable is set
  #
  # @return [GdsApi::EmailAlertApi]
  def self.email_alert_api(options = {})
    GdsApi::EmailAlertApi.new(
      Plek.find("email-alert-api"),
      { bearer_token: ENV["EMAIL_ALERT_API_BEARER_TOKEN"] }.merge(options),
    )
  end

  # Creates a GdsApi::PlacesManager adapter
  #
  # @return [GdsApi::PlacesManager]
  def self.places_manager(options = {})
    GdsApi::PlacesManager.new(Plek.find("places-manager"), options)
  end

  # Creates a GdsApi::LicenceApplication
  #
  # @return [GdsApi::LicenceApplication]
  def self.licence_application(options = {})
    GdsApi::LicenceApplication.new(Plek.find("licensify"), options)
  end

  # Creates a GdsApi::LinkCheckerApi adapter
  #
  # This will set a bearer token if a LINK_CHECKER_API_BEARER_TOKEN environment
  # variable is set
  #
  # @return [GdsApi::LinkCheckerApi]
  def self.link_checker_api(options = {})
    GdsApi::LinkCheckerApi.new(
      Plek.find("link-checker-api"),
      { bearer_token: ENV["LINK_CHECKER_API_BEARER_TOKEN"] }.merge(options),
    )
  end

  # Creates a GdsApi::LocalLinksManager adapter
  #
  # @return [GdsApi::LocalLinksManager]
  def self.local_links_manager(options = {})
    GdsApi::LocalLinksManager.new(Plek.find("local-links-manager"), options)
  end

  # Creates a GdsApi::LocationsApi adapter
  #
  # @return [GdsApi::LocationsApi]
  def self.locations_api(options = {})
    GdsApi::LocationsApi.new(Plek.find("locations-api"), options)
  end

  # Creates a GdsApi::Organisations adapter for accessing Whitehall
  # APIs through the origin, where the requests will be handled by
  # Collections frontend.
  #
  # @return [GdsApi::Organisations]
  def self.organisations(options = {})
    GdsApi::Organisations.new(Plek.new.website_root, options)
  end

  # Creates a GdsApi::PublishingApi adapter
  #
  # This will set a bearer token if a PUBLISHING_API_BEARER_TOKEN environment
  # variable is set
  #
  # @return [GdsApi::PublishingApi]
  def self.publishing_api(options = {})
    GdsApi::PublishingApi.new(
      Plek.find("publishing-api"),
      { bearer_token: ENV["PUBLISHING_API_BEARER_TOKEN"] }.merge(options),
    )
  end

  # Creates a GdsApi::SignonApi adapter
  #
  # This will set a bearer token if a PUBLISHING_API_BEARER_TOKEN environment
  # variable is set
  #
  # @return [GdsApi::SignonApi]
  def self.signon_api(options = {})
    GdsApi::SignonApi.new(
      Plek.find("signon"),
      { bearer_token: ENV["SIGNON_API_BEARER_TOKEN"] }.merge(options),
    )
  end

  # Creates a GdsApi::Search adapter to access via a search.* hostname
  #
  # @return [GdsApi::Search]
  def self.search(options = {})
    GdsApi::Search.new(Plek.find("search-api"), options)
  end

  # Creates a GdsApi::Support adapter
  #
  # @return [GdsApi::Support]
  def self.support(options = {})
    GdsApi::Support.new(Plek.find("support"), options)
  end

  # Creates a GdsApi::SupportApi adapter
  #
  # This will set a bearer token if a SUPPORT_API_BEARER_TOKEN environment
  # variable is set
  #
  # @return [GdsApi::SupportApi]
  def self.support_api(options = {})
    GdsApi::SupportApi.new(
      Plek.find("support-api"),
      { bearer_token: ENV["SUPPORT_API_BEARER_TOKEN"] }.merge(options),
    )
  end

  # Creates a GdsApi::Worldwide adapter for accessing Whitehall APIs on a
  # whitehall-frontend host
  #
  # @return [GdsApi::Worldwide]
  def self.worldwide(options = {})
    GdsApi::Worldwide.new(Plek.new.website_root, options)
  end
end
