module GdsApi
  module TestHelpers
    module Calendars
      def calendars_endpoint(in_division: nil)
        endpoint = "#{Plek.new.website_root}/bank-holidays"
        endpoint += "/#{in_division}" unless in_division.nil?
        "#{endpoint}.json"
      end

      def stub_calendars_has_no_bank_holidays(in_division: nil)
        stub_calendars_has_bank_holidays_on([], in_division:)
      end

      def stub_calendars_has_bank_holidays_on(dates, in_division: nil)
        events = dates.map.with_index do |date, idx|
          {
            title: "Caturday #{idx}!",
            date: date.to_date.iso8601,
            notes: "Y'know, for cats!",
            bunting: true,
          }
        end

        response =
          if in_division.nil?
            {
              "england-and-wales" => {
                division: "england-and-wales",
                events:,
              },
              "scotland" => {
                division: "scotland",
                events:,
              },
              "northern-ireland" => {
                division: "northern-ireland",
                events:,
              },
            }
          else
            {
              division: in_division,
              events:,
            }
          end

        stub_request(:get, calendars_endpoint(in_division:))
          .to_return(body: response.to_json, status: 200)
      end

      def stub_calendars_has_a_bank_holiday_on(date, in_division: nil)
        stub_calendars_has_bank_holidays_on([date], in_division:)
      end
    end
  end
end
