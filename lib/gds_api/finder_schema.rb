class GdsApi::FinderSchema
  NotFoundError = Class.new(RuntimeError)

  def initialize(schema_hash)
    @schema_hash = schema_hash
  end

  def user_friendly_values(document_attributes)
    document_attributes.each_with_object({}) do |(k, v), values|
      values.store(
        user_friendly_facet_label(k.to_s),
        user_friendly_facet_value(k.to_s, v),
      )
    end
  end

  attr_reader :schema_hash
  private :schema_hash

  private

  def slug
    schema_hash.fetch("slug")
  end

  def user_friendly_facet_label(facet_key)
    find_facet(facet_key.to_s).fetch("name")
  end

  def user_friendly_facet_value(facet_key, value)
    Array(value).map { |value|
      find_schema_allowed_value_label(facet_key, value)
    }
  end

  def find_schema_allowed_value_label(facet_key, value)
    value_label_pair = allowed_values_for(facet_key)
      .find { |schema_value|
        schema_value.fetch("value") == value
      }

    if value_label_pair.nil?
      raise_value_not_found_error(facet_key, value)
    else
      value_label_pair.fetch("label")
    end
  end

  def allowed_values_for(facet_key)
    find_facet(facet_key).fetch("allowed_values")
  end

  def find_facet(facet_key)
    facets.find { |facet| facet.fetch("key") == facet_key }
  end

  def facets
    schema_hash.fetch("facets")
  end

  def raise_value_not_found_error(facet_key, value)
    raise NotFoundError.new("#{facet_key} value '#{value}' not found in #{slug} schema")
  end
end
