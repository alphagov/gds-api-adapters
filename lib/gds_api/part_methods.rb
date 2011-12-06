module GdsApi::PartMethods

  def part_index(slug)
    parts.index { |p| p.slug == slug }
  end

  def find_part(slug)
    return nil unless index = part_index(slug)
    parts[index]
  end

  def has_parts?(part)
    !! (has_previous_part?(part) || has_next_part?(part))
  end

  def has_previous_part?(part)
    index = part_index(part.slug)
    !! (index && index > 0)
  end

  def has_next_part?(part)
    index = part_index(part.slug)
    !! (index && (index + 1) < parts.length)
  end

  def part_after(part)
    part_at(part, 1)
  end

  def part_before(part)
    part_at(part, -1)
  end

private
  def part_at(part, relative_offset)
    return nil unless current_index = part_index(part.slug)
    other_index = current_index + relative_offset
    return nil unless (0 ... parts.length).include?(other_index)
    parts[other_index]
  end
end
