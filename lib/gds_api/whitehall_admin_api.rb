require_relative 'base'

class GdsApi::WhitehallAdminApi < GdsApi::Base
  def reindex_specialist_sector_editions(slug)
    post_json!("#{endpoint}/reindex-specialist-sector-editions/#{slug}")
  end

private

  def endpoint
    "#{super}/government/admin/api"
  end
end
