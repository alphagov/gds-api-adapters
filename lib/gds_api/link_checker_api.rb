require_relative "base"

class GdsApi::LinkCheckerApi < GdsApi::Base
  # Checks whether a link is broken.
  #
  # Makes a +GET+ request to the link checker api to check a link.
  #
  # @param uri [String] The URI to check.
  # @param synchronous [Boolean] Whether the check should happen immediately. (optional)
  # @param checked_within [Fixnum] The number of seconds the last check should
  #   be within before doing another check. (optional)
  # @return [LinkReport] A +SimpleDelegator+ of the +GdsApi::Response+ which
  #   responds to:
  #     :uri              the URI of the link
  #     :status           the status of the link, one of: ok, pending, broken, caution
  #     :checked          the date the link was checked
  #     :errors           a list of error descriptions
  #     :warnings         a list of warning descriptions
  #     :problem_summary  a short description of the most critical problem with the link
  #     :suggested_fix    where possible, this provides a potential fix for the problem
  #
  # @raise [HTTPErrorResponse] if the request returns an error
  def check(uri, synchronous: nil, checked_within: nil)
    params = {
      uri: uri,
      synchronous: synchronous,
      checked_within: checked_within,
    }

    response = get_json(
      "#{endpoint}/check" + query_string(params.delete_if { |_, v| v.nil? }),
    )

    LinkReport.new(response.to_hash)
  end

  # Create a batch of links to check.
  #
  # Makes a +POST+ request to the link checker api to create a batch.
  #
  # @param uris [Array] A list of URIs to check.
  # @param checked_within [Fixnum] The number of seconds the last check should
  #   be within before doing another check. (optional)
  # @param webhook_uri [String] The URI to be called when the batch finishes. (optional)
  # @param webhook_secret_token [String] A secret token that the API will use to generate a signature of the request. (optional)
  # @return [BatchReport] A +SimpleDelegator+ of the +GdsApi::Response+ which
  #   responds to:
  #     :id            the ID of the batch
  #     :status        the status of the check, one of: complete or in_progress
  #     :links         an array of link reports
  #     :totals        an +OpenStruct+ of total information, fields: links, ok, caution, broken, pending
  #     :completed_at  a date when the batch was completed
  #
  # @raise [HTTPErrorResponse] if the request returns an error
  def create_batch(uris, checked_within: nil, webhook_uri: nil, webhook_secret_token: nil)
    payload = {
      uris: uris,
      checked_within: checked_within,
      webhook_uri: webhook_uri,
      webhook_secret_token: webhook_secret_token,
    }

    response = post_json(
      "#{endpoint}/batch", payload.delete_if { |_, v| v.nil? }
    )

    BatchReport.new(response.to_hash)
  end

  # Get information about a batch.
  #
  # Makes a +GET+ request to the link checker api to get a batch.
  #
  # @param id [Fixnum] The batch ID to get information about.
  # @return [BatchReport] A +SimpleDelegator+ of the +GdsApi::Response+ which
  #   responds to:
  #     :id            the ID of the batch
  #     :status        the status of the check, one of: completed or in_progress
  #     :links         an array of link reports
  #     :totals        an +OpenStruct+ of total information, fields: links, ok, caution, broken, pending
  #     :completed_at  a date when the batch was completed
  #
  # @raise [HTTPErrorResponse] if the request returns an error
  def get_batch(id)
    BatchReport.new(
      get_json(
        "#{endpoint}/batch/#{id}",
      ).to_hash,
    )
  end

  class LinkReport < SimpleDelegator
    def uri
      self["uri"]
    end

    def status
      self["status"].to_sym
    end

    def checked
      Time.iso8601(self["checked"])
    end

    def problem_summary
      self["problem_summary"]
    end

    def suggested_fix
      self["suggested_fix"]
    end

    def errors
      self["errors"]
    end

    def warnings
      self["warnings"]
    end
  end

  class BatchReport < SimpleDelegator
    def id
      self["id"]
    end

    def status
      self["status"].to_sym
    end

    def links
      self["links"].map { |link_report| LinkReport.new(link_report) }
    end

    def totals
      OpenStruct.new(self["totals"])
    end

    def completed_at
      Time.iso8601(self["completed_at"])
    end
  end
end
