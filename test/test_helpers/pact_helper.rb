PUBLISHING_API_PORT = 3001
ORGANISATION_API_PORT = 3002
BANK_HOLIDAYS_API_PORT = 3003
ACCOUNT_API_PORT = 3004
LINK_CHECKER_API_PORT = 3005
IMMINENCE_API_PORT = 3006
WHITEHALL_API_PORT = 3007

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

def imminence_api_host
  "http://localhost:#{IMMINENCE_API_PORT}"
end

def whitehall_api_host
  "http://localhost:#{WHITEHALL_API_PORT}"
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

  has_pact_with "Imminence API" do
    mock_service :imminence_api do
      port IMMINENCE_API_PORT
    end
  end

  has_pact_with "Whitehall API" do
    mock_service :whitehall_api do
      port WHITEHALL_API_PORT
    end
  end
end
