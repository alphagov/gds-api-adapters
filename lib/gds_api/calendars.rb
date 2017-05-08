require_relative 'base'

class GdsApi::Calendars < GdsApi::Base
  def bank_holidays(division = nil)
    json_url = "#{endpoint}/bank-holidays"
    json_url += "/#{division.to_s.tr('_', '-')}" unless division.nil?
    json_url += ".json"
    get_json json_url
  end
end
