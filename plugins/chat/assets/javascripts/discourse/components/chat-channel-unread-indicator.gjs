import Component from "@glimmer/component";
import concatClass from "discourse/helpers/concat-class";

const MAX_UNREAD_COUNT = 99;

export default class ChatChannelUnreadIndicator extends Component {
  get showUnreadIndicator() {
    return (
      this.args.channel.tracking.unreadCount +
        this.args.channel.tracking.mentionCount +
        this.args.channel.unreadThreadsCountSinceLastViewed >
      0
    );
  }

  get publicUrgentCount() {
    return (
      this.args.channel.tracking.mentionCount +
      this.args.channel.tracking.watchedThreadsUnreadCount
    );
  }

  get directUrgentCount() {
    return (
      this.args.channel.tracking.unreadCount +
      this.args.channel.tracking.mentionCount +
      this.args.channel.tracking.watchedThreadsUnreadCount
    );
  }

  get urgentCount() {
    return this.args.channel.isDirectMessageChannel
      ? this.directUrgentCount
      : this.publicUrgentCount;
  }

  get isUrgent() {
    return this.urgentCount > 0;
  }

  get urgentBadgeCount() {
    const totalCount = this.urgentCount;
    return totalCount > MAX_UNREAD_COUNT ? `${MAX_UNREAD_COUNT}+` : totalCount;
  }

  <template>
    {{#if this.showUnreadIndicator}}
      <div
        class={{concatClass
          "chat-channel-unread-indicator"
          (if this.isUrgent "-urgent")
        }}
      >
        <div class="chat-channel-unread-indicator__number">
          {{#if this.isUrgent}}{{this.urgentBadgeCount}}{{else}}&nbsp;{{/if}}
        </div>
      </div>
    {{/if}}
  </template>
}
