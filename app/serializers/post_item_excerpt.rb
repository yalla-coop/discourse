# frozen_string_literal: true

module PostItemExcerpt
  def self.included(base)
    base.attributes(:excerpt, :truncated)
  end

  def cooked
    @cooked ||= object.cooked || object.excerpt || PrettyText.cook(object.raw)
  end

  def excerpt
    return nil unless cooked
    @excerpt ||= @excerpt || cooked
  end

  def truncated
    true
  end

  def include_truncated?
    cooked.length > 300
  end
end
