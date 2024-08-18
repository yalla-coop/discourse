# frozen_string_literal: true

DiscourseEvent.on(:user_confirmed_email) do |user|
  # Log the event

  user_groups = GroupUser.where(user_id: user.id).pluck(:group_id)

  # For each group, get the group object and log it along with the owners information
  user_groups.each do |group_id|
    group = Group.find(group_id)
    owners = group.group_users.where(owner: true).map(&:user) # Fetch all owners

    if owners.any?
      # Send an email to each group owner
      owners.each do |owner|
        UserNotifications.notify_group_owner(
          user.username,
          user.email,
          group.full_name,
          owner.email,
        )
      end
    end
  end
end
