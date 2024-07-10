# frozen_string_literal: true
class ChangeDefaultNotificationLevelsInUserChatChannelMemberships < ActiveRecord::Migration[6.0]
  def change
    change_column_default :user_chat_channel_memberships,
                          :desktop_notification_level,
                          from: 1,
                          to: 2
    change_column_default :user_chat_channel_memberships, :mobile_notification_level, from: 1, to: 2
  end
end
