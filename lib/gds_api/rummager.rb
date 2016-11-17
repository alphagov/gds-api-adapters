require 'gds_api/base'
require 'rack/utils'

module GdsApi
  # @api documented
  class Rummager < Base

    # Perform a search.
    #
    # @param args [Hash] A valid search query. See Rummager documentation for options.
    #
    # @see https://github.com/alphagov/rummager/blob/master/docs/search-api.md
    def search(args)
      request_url = "#{base_url}/search.json?#{Rack::Utils.build_nested_query(args)}"
      get_json!(request_url)
    end

    # Advanced search.
    #
    # @deprecated Only in use by Whitehall. Use the `#search` method.
    def advanced_search(args)
      raise ArgumentError.new("Args cannot be blank") if args.nil? || args.empty?
      request_path = "#{base_url}/advanced_search?#{Rack::Utils.build_nested_query(args)}"
      get_json!(request_path)
    end

    # Add a document to the search index.
    #
    # @param type [String] The rummager/elasticsearch document type.
    # @param id [String] The rummager/elasticsearch id. Typically the same as the `link` field, but this is not strictly enforced.
    # @param document [Hash] The document to add. Must match the rummager schema matchin the `type` parameter and contain a `link` field.
    # @return [GdsApi::Response] A status code of 202 indicates the document has been successfully queued.
    #
    # @see https://github.com/alphagov/rummager/blob/master/docs/documents.md
    def add_document(type, id, document)
      post_json!(
        documents_url,
        document.merge(
          _type: type,
          _id: id,
        )
      )
    end

    # Delete a content-document from the index by base path.
    #
    # Content documents are pages on GOV.UK that have a base path and are
    # returned in searches. This excludes best bets, recommended-links,
    # and contacts, which may be deleted with `delete_document`.
    #
    # @param base_path Base path of the page on GOV.UK.
    # @see https://github.com/alphagov/rummager/blob/master/docs/content-api.md
    def delete_content!(base_path)
      request_url = "#{base_url}/content?link=#{base_path}"
      delete_json!(request_url)
    end

    # Retrieve a content-document from the index.
    #
    # Content documents are pages on GOV.UK that have a base path and are
    # returned in searches. This excludes best bets, recommended-links,
    # and contacts.
    #
    # @param base_path [String] Base path of the page on GOV.UK.
    # @see https://github.com/alphagov/rummager/blob/master/docs/content-api.md
    def get_content!(base_path)
      request_url = "#{base_url}/content?link=#{base_path}"
      get_json!(request_url)
    end

    # Delete a non-content document from the search index.
    #
    # For example, best bets, recommended links, or contacts.
    #
    # @param type [String] The rummager/elasticsearch document type.
    # @param id [String] The rummager/elasticsearch id. Typically the same as the `link` field.
    def delete_document(type, id)
      delete_json!(
        "#{documents_url}/#{id}",
        _type: type,
      )
    end

  private

    def base_url
      endpoint
    end

    def documents_url
      "#{base_url}/documents"
    end
  end
end
