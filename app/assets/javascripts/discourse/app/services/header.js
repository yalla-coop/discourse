import { tracked } from "@glimmer/tracking";
import { registerDestructor } from "@ember/destroyable";
import { dependentKeyCompat } from "@ember/object/compat";
import Service, { service } from "@ember/service";
import { TrackedMap } from "@ember-compat/tracked-built-ins";
import { disableImplicitInjections } from "discourse/lib/implicit-injections";
import deprecated from "discourse-common/lib/deprecated";
import { SCROLLED_UP } from "./scroll-direction";

const VALID_HEADER_BUTTONS_TO_HIDE = ["search", "login", "signup"];

@disableImplicitInjections
export default class Header extends Service {
  @service siteSettings;
  @service scrollDirection;
  @service site;

  /**
   * The topic currently viewed on the page.
   *
   * The information is updated as soon as the page is loaded.
   *
   * @type {Topic|null}
   */
  @tracked topicInfo = null;

  @tracked mainTopicTitleVisible = false;

  @tracked hamburgerVisible = false;
  @tracked userVisible = false;
  @tracked anyWidgetHeaderOverrides = false;

  #hiders = new TrackedMap();

  get topic() {
    deprecated(
      "`.topic` is deprecated in service:header. Use `.topicInfo` or `.topicInfoVisible` instead.",
      {
        id: "discourse.header-service-topic",
        since: "3.3.0.beta4-dev",
        dropFrom: "3.4.0",
      }
    );

    return this.topicInfoVisible ? this.topicInfo : null;
  }

  /**
   * Indicates whether topic info should be displayed
   * in the header.
   */
  @dependentKeyCompat // For legacy `site-header` observer compat
  get topicInfoVisible() {
    if (!this.topicInfo) {
      // Not on a topic page
      return false;
    }

    if (this.mainTopicTitleVisible) {
      // Title is already visible on screen, no need to duplicate
      return false;
    }

    if (
      this.site.mobileView &&
      this.scrollDirection.lastScrollDirection === SCROLLED_UP
    ) {
      // On mobile, we hide the topic info when scrolling up
      return false;
    }

    return true;
  }

  get useGlimmerHeader() {
    if (this.siteSettings.glimmer_header_mode === "disabled") {
      return false;
    } else if (this.siteSettings.glimmer_header_mode === "enabled") {
      if (this.anyWidgetHeaderOverrides) {
        // eslint-disable-next-line no-console
        console.error(
          "Using modern 'glimmer' header, even though there are themes and/or plugins using deprecated APIs. Deprecated header customizations will be broken. (glimmer_header_mode: enabled) https://meta.discourse.org/t/316549"
        );
      }

      return true;
    } else {
      // Auto
      if (this.anyWidgetHeaderOverrides) {
        // eslint-disable-next-line no-console
        console.warn(
          "Using legacy 'widget' header because themes and/or plugins are using deprecated APIs. (glimmer_header_mode: auto) https://meta.discourse.org/t/316549"
        );
        return false;
      } else {
        return true;
      }
    }
  }

  registerHider(ref, buttons) {
    const validButtons = buttons
      .map((button) => {
        if (!VALID_HEADER_BUTTONS_TO_HIDE.includes(button)) {
          // eslint-disable-next-line no-console
          console.error(
            `Invalid button to hide: ${button}, valid buttons are: ${VALID_HEADER_BUTTONS_TO_HIDE.join(
              ","
            )}`
          );
        } else {
          return button;
        }
      })
      .filter(Boolean);

    if (!validButtons.length) {
      return;
    }

    this.#hiders.set(ref, validButtons);

    registerDestructor(ref, () => {
      this.#hiders.delete(ref);
    });
  }

  get headerButtonsHidden() {
    const buttonsToHide = new Set();
    this.#hiders.forEach((buttons) => {
      buttons.forEach((button) => {
        buttonsToHide.add(button);
      });
    });
    return Array.from(buttonsToHide);
  }

  /**
   * Called whenever a topic route is entered. Sets the current topicInfo,
   * and makes a guess about whether the main topic title is likely to be visible
   * on initial load. The IntersectionObserver will correct this later if needed.
   */
  enterTopic(topic, isLoadingFirstPost) {
    this.topicInfo = topic;
    this.mainTopicTitleVisible = isLoadingFirstPost;
  }

  clearTopic() {
    this.topicInfo = null;
    this.mainTopicTitleVisible = false;
  }
}
