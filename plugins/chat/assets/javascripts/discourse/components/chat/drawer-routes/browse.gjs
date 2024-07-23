import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { array } from "@ember/helper";
import { service } from "@ember/service";
import i18n from "discourse-common/helpers/i18n";
import BrowseChannels from "discourse/plugins/chat/discourse/components/browse-channels";
import Navbar from "discourse/plugins/chat/discourse/components/chat/navbar";

export default class ChatDrawerRoutesBrowse extends Component {
  @service chat;
  @service chatStateManager;
  @service chatChannelsManager;
  @service chatHistory;

  @tracked showThreadFullTitle = false;

  get showfullTitle() {
    return this.chatStateManager.isDrawerExpanded && this.showThreadFullTitle;
  }

  <template>
    <div class="c-drawer-routes --browse">
      <Navbar
        @onClick={{this.chat.toggleDrawer}}
        @showFullTitle={{this.showfullTitle}}
        as |navbar|
      >
        <navbar.BackButton @route="chat.channels" />
        <navbar.Title @title={{i18n "chat.browse.title"}} />
        <navbar.Actions as |a|>
          <a.NewChannelButton />
          <a.ToggleDrawerButton />
          <a.FullPageButton />
          <a.CloseDrawerButton />
        </navbar.Actions>
      </Navbar>

      {{#if this.chatStateManager.isDrawerExpanded}}
        <div class="chat-drawer-content">
          {{#each (array @params.currentTab) as |tab|}}
            <BrowseChannels @currentTab={{tab}} />
          {{/each}}
        </div>
      {{/if}}
    </div>
  </template>
}
