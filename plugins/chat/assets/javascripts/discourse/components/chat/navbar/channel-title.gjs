import Component from "@glimmer/component";
import { LinkTo } from "@ember/routing";
import { service } from "@ember/service";
import ChannelTitle from "discourse/plugins/chat/discourse/components/channel-title";

export default class ChatNavbarChannelTitle extends Component {
  @service chatStateManager;

  get shouldLinkToSettings() {
    return (
      this.chatStateManager.isDrawerExpanded ||
      this.chatStateManager.isFullPageActive
    );
  }

  <template>
    {{#if @channel}}
      {{#if this.shouldLinkToSettings}}
        <LinkTo
          @route="chat.channel.info.settings"
          @models={{@channel.routeModels}}
          class="c-navbar__channel-title"
        >
          <ChannelTitle @channel={{@channel}} />
        </LinkTo>
      {{else}}
        <div class="c-navbar__channel-title">
          <ChannelTitle @channel={{@channel}} />
        </div>
      {{/if}}
    {{/if}}
  </template>
}
