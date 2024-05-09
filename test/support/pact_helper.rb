ENV["PACT_DO_NOT_TRACK"] = "true"

PUBLISHING_API_PORT = 3001
ORGANISATION_API_PORT = 3002
BANK_HOLIDAYS_API_PORT = 3003
ACCOUNT_API_PORT = 3004
LINK_CHECKER_API_PORT = 3005
PLACES_MANAGER_API_PORT = 3006
LOCATIONS_API_PORT = 3008
ASSET_MANAGER_API_PORT = 3009
EMAIL_ALERT_API_PORT = 3010

def publishing_api_host
  "http://localhost:#{PUBLISHING_API_PORT}"
end

def organisation_api_host
  "http://localhost:#{ORGANISATION_API_PORT}"
end

def bank_holidays_api_host
  "http://localhost:#{BANK_HOLIDAYS_API_PORT}"
end

def account_api_host
  "http://localhost:#{ACCOUNT_API_PORT}"
end

def link_checker_api_host
  "http://localhost:#{LINK_CHECKER_API_PORT}"
end

def places_manager_api_host
  "http://localhost:#{PLACES_MANAGER_API_PORT}"
end

def locations_api_host
  "http://localhost:#{LOCATIONS_API_PORT}"
end

def asset_manager_api_host
  "http://localhost:#{ASSET_MANAGER_API_PORT}"
end

def email_alert_api_host
  "http://localhost:#{EMAIL_ALERT_API_PORT}"
end

Pact.service_consumer "GDS API Adapters" do
  has_pact_with "Publishing API" do
    mock_service :publishing_api do
      port PUBLISHING_API_PORT
    end
  end

  has_pact_with "Collections Organisation API" do
    mock_service :organisation_api do
      port ORGANISATION_API_PORT
    end
  end

  has_pact_with "Bank Holidays API" do
    mock_service :bank_holidays_api do
      port BANK_HOLIDAYS_API_PORT
    end
  end

  has_pact_with "Account API" do
    mock_service :account_api do
      port ACCOUNT_API_PORT
    end
  end

  has_pact_with "Link Checker API" do
    mock_service :link_checker_api do
      port LINK_CHECKER_API_PORT
    end
  end

  has_pact_with "Places Manager API" do
    mock_service :places_manager_api do
      port PLACES_MANAGER_API_PORT
    end
  end

  has_pact_with "Locations API" do
    mock_service :locations_api do
      port LOCATIONS_API_PORT
    end
  end

  has_pact_with "Asset Manager" do
    mock_service :asset_manager do
      port ASSET_MANAGER_API_PORT
    end
  end

  has_pact_with "Email Alert API" do
    mock_service :email_alert_api do
      port EMAIL_ALERT_API_PORT
    end
  end
end
