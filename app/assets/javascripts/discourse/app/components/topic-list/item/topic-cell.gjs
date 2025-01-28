import Component from "@glimmer/component";
import { hash } from "@ember/helper";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { service } from "@ember/service";
import PluginOutlet from "discourse/components/plugin-outlet";
import ActionList from "discourse/components/topic-list/action-list";
import ParticipantGroups from "discourse/components/topic-list/participant-groups";
import TopicExcerpt from "discourse/components/topic-list/topic-excerpt";
import TopicLink from "discourse/components/topic-list/topic-link";
import UnreadIndicator from "discourse/components/topic-list/unread-indicator";
import TopicPostBadges from "discourse/components/topic-post-badges";
import TopicStatus from "discourse/components/topic-status";
import categoryLink from "discourse/helpers/category-link";
import discourseTags from "discourse/helpers/discourse-tags";
import topicFeaturedLink from "discourse/helpers/topic-featured-link";
import { groupPath } from "discourse/lib/url";
import { i18n } from "discourse-i18n";

export default class TopicCell extends Component {
  @service currentUser;
  @service messageBus;

  get newDotText() {
    return this.currentUser?.trust_level > 0
      ? ""
      : i18n("filters.new.lower_title");
  }

  get participantGroups() {
    if (!this.args.topic.get("participant_groups")) {
      return [];
    }

    return this.args.topic.get("participant_groups").map((name) => ({
      name,
      url: groupPath(name),
    }));
  }

  @action
  onTitleFocus(event) {
    event.target.closest(".topic-list-item").classList.add("selected");
  }

  @action
  onTitleBlur(event) {
    event.target.closest(".topic-list-item").classList.remove("selected");
  }

  <template>
    <td class="main-link clearfix topic-list-data" colspan="1">
      <PluginOutlet
        @name="topic-list-before-link"
        @outletArgs={{hash topic=@topic}}
      />

      <span class="link-top-line" role="heading" aria-level="2">
        {{~! no whitespace ~}}
        <PluginOutlet
          @name="topic-list-before-status"
          @outletArgs={{hash topic=@topic}}
        />
        {{~! no whitespace ~}}
        <PluginOutlet
          @name="topic-list-topic-cell-link-top-line"
          @outletArgs={{hash topic=@topic tagsForUser=@tagsForUser}}
        >
          {{~! no whitespace ~}}
          <TopicStatus @topic={{@topic}} @context="topic-list" />
          {{~! no whitespace ~}}
          <TopicLink
            {{on "focus" this.onTitleFocus}}
            {{on "blur" this.onTitleBlur}}
            @topic={{@topic}}
            class="raw-link raw-topic-link"
          />
          {{~#if @topic.featured_link~}}
            &nbsp;
            {{~topicFeaturedLink @topic}}
          {{~/if~}}
          <PluginOutlet
            @name="topic-list-after-title"
            @outletArgs={{hash topic=@topic}}
          />
          {{~! no whitespace ~}}
          <UnreadIndicator @topic={{@topic}} />
          {{~#if @showTopicPostBadges~}}
            <TopicPostBadges
              @unreadPosts={{@topic.unread_posts}}
              @unseen={{@topic.unseen}}
              @newDotText={{this.newDotText}}
              @url={{@topic.lastUnreadUrl}}
            />
          {{~/if~}}
        </PluginOutlet>
      </span>

      <div class="link-bottom-line">
        <PluginOutlet
          @name="topic-list-topic-cell-link-bottom-line"
          @outletArgs={{hash topic=@topic tagsForUser=@tagsForUser}}
        >
          {{#unless @hideCategory}}
            {{#unless @topic.isPinnedUncategorized}}
              <PluginOutlet
                @name="topic-list-before-category"
                @outletArgs={{hash topic=@topic}}
              />
              {{categoryLink @topic.category}}
              <PluginOutlet
                @name="topic-list-after-category"
                @outletArgs={{hash topic=@topic}}
              />
            {{/unless}}
          {{/unless}}

          {{discourseTags @topic mode="list" tagsForUser=@tagsForUser}}

          {{#if this.participantGroups}}
            <ParticipantGroups @groups={{this.participantGroups}} />
          {{/if}}

          <ActionList
            @topic={{@topic}}
            @postNumbers={{@topic.liked_post_numbers}}
            @icon="heart"
            class="likes"
          />
        </PluginOutlet>
      </div>

      {{#if @expandPinned}}
        <TopicExcerpt @topic={{@topic}} />
      {{/if}}

      <PluginOutlet
        @name="topic-list-main-link-bottom"
        @outletArgs={{hash topic=@topic}}
      />
    </td>
  </template>
}
