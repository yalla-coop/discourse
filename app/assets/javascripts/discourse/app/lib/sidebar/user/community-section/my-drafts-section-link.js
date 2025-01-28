import { tracked } from "@glimmer/tracking";
import BaseSectionLink from "discourse/lib/sidebar/base-community-section-link";
import { i18n } from "discourse-i18n";

const USER_DRAFTS_CHANGED_EVENT = "user-drafts:changed";

export default class MyDraftsSectionLink extends BaseSectionLink {
  @tracked draftCount = this.currentUser?.draft_count;

  constructor() {
    super(...arguments);

    if (this.currentUser) {
      this.appEvents.on(
        USER_DRAFTS_CHANGED_EVENT,
        this,
        this._updateDraftCount
      );
    }
  }

  teardown() {
    if (this.currentUser) {
      this.appEvents.off(
        USER_DRAFTS_CHANGED_EVENT,
        this,
        this._updateDraftCount
      );
    }
  }

  _updateDraftCount() {
    this.draftCount = this.currentUser.draft_count;
  }

  get showCount() {
    return this.currentUser?.sidebarShowCountOfNewItems;
  }

  get name() {
    return "my-drafts";
  }

  get route() {
    return "userActivity.drafts";
  }

  get model() {
    return this.currentUser;
  }

  get title() {
    return i18n("sidebar.sections.community.links.my_drafts.title");
  }

  get text() {
    return i18n("sidebar.sections.community.links.my_drafts.content");
  }

  get badgeText() {
    if (!this.showCount || !this._hasDraft) {
      return;
    }

    if (this.currentUser.new_new_view_enabled) {
      return this.draftCount.toString();
    } else {
      return i18n("sidebar.sections.community.links.my_drafts.draft_count", {
        count: this.draftCount,
      });
    }
  }

  get _hasDraft() {
    return this.draftCount > 0;
  }

  get suffixCSSClass() {
    return "unread";
  }

  get suffixType() {
    return "icon";
  }

  get suffixValue() {
    if (this._hasDraft && !this.showCount) {
      return "circle";
    }
  }

  get shouldDisplay() {
    return this.currentUser && this._hasDraft;
  }

  get prefixValue() {
    return "far-pen-to-square";
  }
}
