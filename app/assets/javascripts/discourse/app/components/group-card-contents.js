import { action } from "@ember/object";
import { alias, gt } from "@ember/object/computed";
import { service } from "@ember/service";
import { classNameBindings, classNames } from "@ember-decorators/component";
import CardContentsBase from "discourse/components/card-contents-base";
import { setting } from "discourse/lib/computed";
import { wantsNewWindow } from "discourse/lib/intercept-click";
import { groupPath } from "discourse/lib/url";
import CleansUp from "discourse/mixins/cleans-up";
import discourseComputed from "discourse-common/utils/decorators";

const maxMembersToDisplay = 10;

@classNames("no-bg", "group-card")
@classNameBindings(
  "visible:show",
  "showBadges",
  "hasCardBadgeImage",
  "isFixed:fixed",
  "groupClass"
)
export default class GroupCardContents extends CardContentsBase.extend(
  CleansUp
) {
  @service composer;
  @setting("allow_profile_backgrounds") allowBackgrounds;
  @setting("enable_badges") showBadges;

  @alias("topic.postStream") postStream;
  @gt("moreMembersCount", 0) showMoreMembers;

  elementId = "group-card";
  mentionSelector = "a.mention-group";

  group = null;

  @discourseComputed("group.members.[]")
  highlightedMembers(members) {
    return members.slice(0, maxMembersToDisplay);
  }

  @discourseComputed("group.user_count", "group.members.[]")
  moreMembersCount(memberCount) {
    return Math.max(memberCount - maxMembersToDisplay, 0);
  }

  @discourseComputed("group.name")
  groupClass(name) {
    return name ? `group-card-${name}` : "";
  }

  @discourseComputed("group")
  groupPath(group) {
    return groupPath(group.name);
  }

  async _showCallback(username) {
    this.setProperties({ visible: true, loading: true });

    try {
      const group = await this.store.find("group", username);
      this.setProperties({ group });

      if (!group.flair_url && !group.flair_bg_color) {
        group.set("flair_url", "fa-users");
      }

      if (group.can_see_members && group.members.length < maxMembersToDisplay) {
        return group.reloadMembers({ limit: maxMembersToDisplay }, true);
      }
    } catch {
      this._close();
    } finally {
      this.set("loading", null);
    }
  }

  _close() {
    this.set("group", null);

    super._close(...arguments);
  }

  cleanUp() {
    this._close();
  }

  @action
  close(event) {
    event?.preventDefault();
    this._close();
  }

  @action
  handleShowGroup(event) {
    if (wantsNewWindow(event)) {
      return;
    }

    event.preventDefault();
    // Invokes `showGroup` argument. Convert to `this.args.showGroup` when
    // refactoring this to a glimmer component.
    this.showGroup(this.group);
    this._close();
  }

  @action
  cancelFilter() {
    this.postStream.cancelFilter();
    this.postStream.refresh();
    this._close();
  }

  @action
  messageGroup() {
    this.composer.openNewMessage({
      recipients: this.get("group.name"),
      hasGroups: true,
    });
  }
}
