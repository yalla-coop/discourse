# frozen_string_literal: true

class BasicCategorySerializer < ApplicationSerializer
  attributes :id,
             :name,
             :color,
             :text_color,
             :slug,
             :topic_count,
             :post_count,
             :position,
             :description,
             :description_text,
             :description_excerpt,
             :topic_url,
             :read_restricted,
             :permission,
             :parent_category_id,
             :notification_level,
             :can_edit,
             :topic_template,
             :has_children,
             :subcategory_count,
             :sort_order,
             :sort_ascending,
             :show_subcategory_list,
             :num_featured_topics,
             :default_view,
             :subcategory_list_style,
             :default_top_period,
             :default_list_filter,
             :minimum_required_tags,
             :navigate_to_first_post_after_read,
             :custom_fields,
             :group_permissions

  has_one :uploaded_logo, embed: :object, serializer: CategoryUploadSerializer
  has_one :uploaded_logo_dark, embed: :object, serializer: CategoryUploadSerializer
  has_one :uploaded_background, embed: :object, serializer: CategoryUploadSerializer

  def group_permissions
    @group_permissions ||=
      begin
        perms =
          object
            .category_groups
            .joins(:group)
            .includes(:group)
            .merge(Group.visible_groups(scope&.user, "groups.name ASC", include_everyone: true))
            .map { |cg| { permission_type: cg.permission_type, group_name: cg.group.name } }

        if perms.length == 0 && !object.read_restricted
          perms << {
            permission_type: CategoryGroup.permission_types[:full],
            group_name: Group[:everyone]&.name.presence || :everyone,
          }
        end

        perms
      end
  end

  def include_parent_category_id?
    parent_category_id
  end

  def name
    if object.uncategorized?
      I18n.t("uncategorized_category_name", locale: SiteSetting.default_locale)
    else
      object.name
    end
  end

  def description_text
    if object.uncategorized?
      I18n.t("category.uncategorized_description", locale: SiteSetting.default_locale)
    else
      object.description_text
    end
  end

  def description
    if object.uncategorized?
      I18n.t("category.uncategorized_description", locale: SiteSetting.default_locale)
    else
      object.description
    end
  end

  def description_excerpt
    if object.uncategorized?
      I18n.t("category.uncategorized_description", locale: SiteSetting.default_locale)
    else
      object.description_excerpt
    end
  end

  def can_edit
    true
  end

  def include_can_edit?
    scope && scope.can_edit?(object)
  end

  def notification_level
    object.notification_level
  end

  def custom_fields
    object.preloaded_custom_fields
  end

  def include_custom_fields?
    custom_fields.present?
  end
end
