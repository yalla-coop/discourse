# frozen_string_literal: true

module Jobs
  module Chat
    class NotifyWatching < ::Jobs::Base
      def execute(args = {})
        @chat_message =
          ::Chat::Message.includes(:user, chat_channel: :chatable).find_by(
            id: args[:chat_message_id],
          )
        return if @chat_message.nil?

        @creator = @chat_message.user
        @chat_channel = @chat_message.chat_channel
        @is_direct_message_channel = @chat_channel.direct_message_channel?

        # never: 0, mention: 1, always: 2
        never_notification_level = 0

        always_notification_level = ::Chat::UserChatChannelMembership::NOTIFICATION_LEVELS[:always]
        members =
          ::Chat::UserChatChannelMembership
            .includes(user: :groups)
            .joins(user: :user_option)
            .where(user_option: { chat_enabled: true })
            .where(chat_channel_id: @chat_channel.id)
            .where(following: true)
            .where(
              "notification_level = :always OR users.id IN (SELECT user_id FROM user_chat_thread_memberships WHERE thread_id = :thread_id AND notification_level = :watching)",
              always: always_notification_level,
              thread_id: @chat_message.thread_id,
              watching: ::Chat::NotificationLevels.all[:watching],
            )
            .merge(User.not_suspended)
            .where("mobile_notification_level != ?", never_notification_level)

        always_notification_level = "always"
        mention_notification_level = "mention"

        if @is_direct_message_channel
          ::UserCommScreener
            .new(acting_user: @creator, target_user_ids: members.map(&:user_id))
            .allowing_actor_communication
            .each do |user_id|
              send_notifications(members.find { |member| member.user_id == user_id })
            end
        else
          members.each do |member|
            if args[:mentioned_user_ids].include?(member.user_id) &&
                 member.mobile_notification_level == mention_notification_level
              send_notifications(member)
            elsif member.mobile_notification_level == always_notification_level
              send_notifications(member)
            end
          end
        end
      end

      def send_notifications(membership)
        user = membership.user
        return unless user.guardian.can_join_chat_channel?(@chat_channel)
        if ::Chat::Notifier.user_has_seen_message?(
             membership,
             @chat_message.id,
             @chat_message.created_at,
           )
          return
        end

        translation_key =
          (
            if @is_direct_message_channel
              if @chat_channel.chatable.group
                "discourse_push_notifications.popup.new_chat_message"
              else
                "discourse_push_notifications.popup.new_direct_chat_message"
              end
            else
              "discourse_push_notifications.popup.new_chat_message"
            end
          )

        translation_args = { username: @creator.username }
        translation_args[:channel] = @chat_channel.title(user) unless @is_direct_message_channel &&
          !@chat_channel.chatable.group
        translation_args =
          DiscoursePluginRegistry.apply_modifier(
            :chat_notification_translation_args,
            translation_args,
          )

        translated_title =
          I18n.with_locale(user.effective_locale) { I18n.t(translation_key, translation_args) }

        payload = {
          username: @creator.username,
          notification_type: ::Notification.types[:chat_message],
          post_url: @chat_message.url,
          translated_title: translated_title,
          tag: ::Chat::Notifier.push_notification_tag(:message, @chat_channel.id),
          excerpt: @chat_message.push_notification_excerpt,
          channel_id: @chat_channel.id,
          is_direct_message_channel: @is_direct_message_channel,
        }

        if @chat_message.in_thread? && !membership.muted?
          thread_membership =
            ::Chat::UserChatThreadMembership.find_by(
              user_id: user.id,
              thread_id: @chat_message.thread_id,
              notification_level: "watching",
            )

          thread_membership && create_watched_thread_notification(thread_membership)
        end

        if membership.notifications_always? && !membership.muted?
          send_notification =
            DiscoursePluginRegistry.push_notification_filters.all? do |filter|
              filter.call(user, payload)
            end
          if send_notification
            ::MessageBus.publish(
              "/chat/notification-alert/#{user.id}",
              payload,
              user_ids: [user.id],
            )
          end

          ::PostAlerter.push_notification(user, payload)
        end

        create_notification_record(membership)
      end

      def create_notification_record(membership)
        notification_data = {
          chat_message_id: @chat_message.id,
          chat_channel_id: @chat_channel.id,
          channel_name: @chat_channel.name,
          sender: @creator.username,
          is_direct_message_channel: @chat_channel.direct_message_channel?,
          message: @chat_message.message,
        }

        notification_data[:chat_channel_title] = @chat_channel.title(
          membership.user,
        ) unless @is_direct_message_channel
        notification_data[:chat_channel_slug] = @chat_channel.slug unless @is_direct_message_channel

        is_read =
          ::Chat::Notifier.user_has_seen_message?(
            membership,
            @chat_message.id,
            @chat_message.created_at,
          )
        ::Notification.create!(
          notification_type: ::Notification.types[:chat_message],
          user_id: membership.user_id,
          high_priority: true,
          data: notification_data.to_json,
          read: is_read,
        )
        DiscourseEvent.trigger(
          :created_chat_notification,
          notification_data,
          membership.user_id,
          ::Notification.types[:chat_message],
        )
      end

      def create_watched_thread_notification(thread_membership)
        thread = @chat_message.thread
        description = thread.title.presence || thread.original_message.message

        data = {
          username: @creator.username,
          chat_message_id: @chat_message.id,
          chat_channel_id: @chat_channel.id,
          chat_thread_id: @chat_message.thread_id,
          last_read_message_id: thread_membership&.last_read_message_id,
          description: description,
          user_ids: [@chat_message.user_id],
        }

        Notification.consolidate_or_create!(
          notification_type: ::Notification.types[:chat_watched_thread],
          user_id: thread_membership.user_id,
          data: data.to_json,
        )
      end
    end
  end
end
