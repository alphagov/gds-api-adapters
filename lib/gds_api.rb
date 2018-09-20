require 'plek'
require 'gds_api/asset_manager'
require 'gds_api/calendars'
require 'gds_api/content_store'
require 'gds_api/email_alert_api'
require 'gds_api/imminence'
require 'gds_api/licence_application'
require 'gds_api/link_checker_api'
require 'gds_api/local_links_manager'
require 'gds_api/mapit'
require 'gds_api/maslow'
require 'gds_api/organisations'
require 'gds_api/publishing_api'
require 'gds_api/publishing_api_v2'
require 'gds_api/router'
require 'gds_api/rummager'
require 'gds_api/support'
require 'gds_api/support_api'
require 'gds_api/worldwide'

# @api documented
module GdsApi
  # Creates a GdsApi::AssetManager adapter
  #
  # This will set a bearer token if a ASSET_MANAGER_BEARER_TOKEN environment
  # variable is set
  #
  # @return [GdsApi::AssetManager]
  def self.asset_manager(options = {})
    GdsApi::AssetManager.new(
      Plek.find('asset-manager'),
      { bearer_token: ENV['ASSET_MANAGER_BEARER_TOKEN'] }.merge(options)
    )
  end

  # Creates a GdsApi::Calendars adapter
  #
  # @return [GdsApi::Calendars]
  def self.calendars(options = {})
    GdsApi::Calendars.new(Plek.find('calendars'), options)
  end

  # Creates a GdsApi::ContentStore adapter
  #
  # @return [GdsApi::ContentStore]
  def self.content_store(options = {})
    GdsApi::ContentStore.new(Plek.find('content-store'), options)
  end

  # Creates a GdsApi::EmailAlertApi adapter
  #
  # This will set a bearer token if a EMAIL_ALERT_API_BEARER_TOKEN environment
  # variable is set
  #
  # @return [GdsApi::EmailAlertApi]
  def self.email_alert_api(options = {})
    GdsApi::EmailAlertApi.new(
      Plek.find('email-alert-api'),
      { bearer_token: ENV['EMAIL_ALERT_API_BEARER_TOKEN'] }.merge(options)
    )
  end

  # Creates a GdsApi::Imminence adapter
  #
  # @return [GdsApi::Imminence]
  def self.imminence(options = {})
    GdsApi::Imminence.new(Plek.find('imminence'), options)
  end

  # Creates a GdsApi::LicenceApplication
  #
  # @return [GdsApi::LicenceApplication]
  def self.licence_application(options = {})
    GdsApi::LicenceApplication.new(Plek.find('licensify'), options)
  end

  # Creates a GdsApi::LinkCheckerApi adapter
  #
  # @return [GdsApi::LinkCheckerApi]
  def self.link_checker_api(options = {})
    GdsApi::LinkCheckerApi.new(Plek.find('link-checker-api'), options)
  end

  # Creates a GdsApi::LocalLinksManager adapter
  #
  # @return [GdsApi::LocalLinksManager]
  def self.local_links_manager(options = {})
    GdsApi::LocalLinksManager.new(Plek.find('local-links-manager'), options)
  end

  # Creates a GdsApi::Mapit adapter
  #
  # @return [GdsApi::Mapit]
  def self.mapit(options = {})
    GdsApi::Mapit.new(Plek.find('mapit'), options)
  end

  # Creates a GdsApi::Maslow adapter
  #
  # It's set to use an external url as an endpoint as the Maslow adapter is
  # used to generate external links
  #
  # @return [GdsApi::Maslow]
  def self.maslow(options = {})
    GdsApi::Maslow.new(Plek.new.external_url_for('maslow'), options)
  end

  # Creates a GdsApi::Organisations adapter for accessing Whitehall APIs on a
  # whitehall-admin host
  #
  # @return [GdsApi::Organisations]
  def self.organisations(options = {})
    GdsApi::Organisations.new(Plek.find('whitehall-admin'), options)
  end

  # Creates a GdsApi::PublishingApi adapter
  #
  # This will set a bearer token if a PUBLISHING_API_BEARER_TOKEN environment
  # variable is set
  #
  # @return [GdsApi::PublishingApi]
  def self.publishing_api(options = {})
    GdsApi::PublishingApi.new(
      Plek.find('publishing-api'),
      { bearer_token: ENV['PUBLISHING_API_BEARER_TOKEN'] }.merge(options)
    )
  end

  # Creates a GdsApi::PublishingApiV2 adapter
  #
  # This will set a bearer token if a PUBLISHING_API_BEARER_TOKEN environment
  # variable is set
  #
  # @return [GdsApi::PublishingApiV2]
  def self.publishing_api_v2(options = {})
    GdsApi::PublishingApiV2.new(
      Plek.find('publishing-api'),
      { bearer_token: ENV['PUBLISHING_API_BEARER_TOKEN'] }.merge(options)
    )
  end

  # Creates a GdsApi::Router adapter for communicating with Router API
  #
  # @return [GdsApi::Router]
  def self.router(options = {})
    GdsApi::Router.new(Plek.find('router-api'), options)
  end

  # Creates a GdsApi::Rummager adapter to access via a rummager.* hostname
  #
  # @return [GdsApi::Rummager]
  def self.rummager(options = {})
    GdsApi::Rummager.new(Plek.find('rummager'), options)
  end

  # Creates a GdsApi::Rummager adapter to access via a search.* hostname
  #
  # @return [GdsApi::Rummager]
  def self.search(options = {})
    GdsApi::Rummager.new(Plek.find('search'), options)
  end

  # Creates a GdsApi::Support adapter
  #
  # @return [GdsApi::Support]
  def self.support(options = {})
    GdsApi::Support.new(Plek.find('support'), options)
  end

  # Creates a GdsApi::SupportApi adapter
  #
  # @return [GdsApi::SupportApi]
  def self.support_api(options = {})
    GdsApi::SupportApi.new(Plek.find('support-api'), options)
  end

  # Creates a GdsApi::Worldwide adapter for accessing Whitehall APIs on a
  # whitehall-admin host
  #
  # @return [GdsApi::Worldwide]
  def self.worldwide(options = {})
    GdsApi::Worldwide.new(Plek.find('whitehall-admin'), options)
  end
end
