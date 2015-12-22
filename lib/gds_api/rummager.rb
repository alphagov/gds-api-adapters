require 'gds_api/base'
require 'rack/utils'

module GdsApi
  class Rummager < Base

    def unified_search(args)
      request_url = "#{base_url}/unified_search.json?#{Rack::Utils.build_nested_query(args)}"
      get_json!(request_url)
    end

    def advanced_search(args)
      raise ArgumentError.new("Args cannot be blank") if args.nil? || args.empty?
      request_path = "#{base_url}/advanced_search?#{Rack::Utils.build_nested_query(args)}"
      get_json!(request_path)
    end

    def add_document(type, id, document)
      post_json!(
        documents_url,
        document.merge(
          _type: type,
          _id: id,
        )
      )
    end

    # Deletes a content-document from the index. Content documents are pages
    # on GOV.UK returned by search index. They don't include best bets and other
    # "meta" documents that are stored in Rummager.
    #
    # @param base_path Base path of the page on GOV.UK.
    # @see https://github.com/alphagov/rummager/blob/master/docs/content-api.md
    def delete_content!(base_path)
      request_url = "#{base_url}/content?link=#{base_path}"
      delete_json!(request_url)
    end

    # Retrieves a content-document from the index. Content documents are pages
    # on GOV.UK returned by search index.
    #
    # @param base_path Base path of the page on GOV.UK.
    # @see https://github.com/alphagov/rummager/blob/master/docs/content-api.md
    def get_content!(base_path)
      request_url = "#{base_url}/content?link=#{base_path}"
      get_json!(request_url)
    end

    # delete_document(type, id) (DEPRECATED)
    #
    # Delete any document from the search index. Unlike `delete_content!` this
    # needs a type, but can be used to delete non-content documents from the
    # index.
    # @deprecated
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
