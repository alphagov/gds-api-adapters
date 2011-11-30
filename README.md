A set of API adapters to work with the GDS APIs, extracted from the frontend app.

Example usage:

  publisher_api = GdsApi::Publisher.new("http://publisher.environment.alphagov.co.uk")
  ostruct_publication = publisher.publication_for_slug('my-published-item')

  panopticon_api = GdsApi::Panopticon.new("http://panopticon.environment.alphagov.co.uk")
  ostruct_metadata = panopticon_api.artefact_for_slug('my-published-item')

Very much still a work in progress.