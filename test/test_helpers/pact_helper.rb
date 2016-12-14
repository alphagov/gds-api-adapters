PUBLISHING_API_PORT = 3001

def publishing_api_host
  "http://localhost:#{PUBLISHING_API_PORT}"
end

Pact.service_consumer "GDS API Adapters" do
  has_pact_with "Publishing API" do
    mock_service :publishing_api do
      port PUBLISHING_API_PORT
    end
  end
end

Pact.configure do |config|
  config.doc_dir = './doc'
  config.doc_generator = :markdown
end
