PUBLISHING_API_PORT = 3000
ORGANISATION_API_PORT = 3000
# BANK_HOLIDAYS_API_PORT = 3003
ACCOUNT_API_PORT = 3000

def publishing_api_host
  "http://localhost:#{PUBLISHING_API_PORT}"
end

def organisation_api_host
  "http://localhost:#{ORGANISATION_API_PORT}"
end

# def bank_holidays_api_host
#   "http://localhost:#{BANK_HOLIDAYS_API_PORT}"
# end

def account_api_host
  "http://localhost:#{ACCOUNT_API_PORT}"
end

Pact.service_consumer "GDS API Adapters" do
  has_pact_with "Publishing API" do
    mock_service :publishing_api do
      port PUBLISHING_API_PORT
    end
  end
end

Pact.service_consumer "GDS API Adapters" do
  has_pact_with "Collections Organisation API" do
    mock_service :organisation_api do
      port ORGANISATION_API_PORT
    end
  end
end

Pact.service_consumer "GDS API Adapters" do
  has_pact_with "Bank Holidays API" do
    mock_service :bank_holidays_api do
      port 3000
    end
  end
end

Pact.service_consumer "GDS API Adapters" do
  has_pact_with "Account API" do
    mock_service :account_api do
      port ACCOUNT_API_PORT
    end
  end
end
