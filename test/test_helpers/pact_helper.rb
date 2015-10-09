Pact.service_consumer "GDS API Adapters" do
  has_pact_with "Publishing API" do
    mock_service :publishing_api do
      port 3093
    end
  end
end

Pact.configure do |config|
  config.doc_dir = './doc'
  config.doc_generator = :markdown
end
