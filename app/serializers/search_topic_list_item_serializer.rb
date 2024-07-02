# frozen_string_literal: true

class SearchTopicListItemSerializer < ListableTopicSerializer
  include TopicTagsMixin

  attributes :category_id

  def include_image_url?
    true
  end

  def include_thumbnails?
    true
  end
end
