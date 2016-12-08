require_relative 'base'

class GdsApi::Organisations < GdsApi::Base
  def organisations
    get_list! "#{base_url}/organisations"
  end

  def organisation(organisation_slug)
    get_json "#{base_url}/organisations/#{organisation_slug}"
  end

private

  def base_url
    "#{endpoint}/api"
  end
end
