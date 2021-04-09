Pact.service_consumer "GDS API Adapters" do
  has_pact_with "Publishing API" do
    mock_service :publishing_api do
      port PUBLISHING_API_PORT GdsTest::Pact.host_port(:publishing_api)
    end
  end
end

Pact.service_consumer "GDS API Adapters" do
  has_pact_with "Collections Organisation API" do
    mock_service :organisation_api do
      port GdsTest::Pact.host_port(:organisation_api)
    end
  end
end

Pact.service_consumer "GDS API Adapters" do
  has_pact_with "Bank Holidays API" do
    mock_service :bank_holidays_api do
      port GdsTest::Pact.host_port(:bank_holidays_api)
    end
  end
end

Pact.service_consumer "GDS API Adapters" do
  has_pact_with "Account API" do
    mock_service :account_api do
      port GdsTest::Pact.host_port(:account_api)
    end
  end
end
