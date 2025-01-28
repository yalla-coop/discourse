import { click, fillIn, visit } from "@ember/test-helpers";
import { IMAGE_VERSION as v } from "pretty-text/emoji/version";
import { test } from "qunit";
import emojiPicker from "discourse/tests/helpers/emoji-picker-helper";
import {
  acceptance,
  simulateKey,
  simulateKeys,
} from "discourse/tests/helpers/qunit-helpers";

acceptance("Emoji", function (needs) {
  needs.user();

  test("emoji is cooked properly", async function (assert) {
    await visit("/t/internationalization-localization/280");
    await click("#topic-footer-buttons .btn.create");

    await simulateKeys(".d-editor-input", "a :blonde_wo\t");

    assert
      .dom(".d-editor-preview")
      .hasHtml(
        `<p>a <img src="/images/emoji/twitter/blonde_woman.png?v=${v}" title=":blonde_woman:" class="emoji" alt=":blonde_woman:" loading="lazy" width="20" height="20" style="aspect-ratio: 20 / 20;"></p>`
      );
  });

  test("emoji can be picked from the emoji-picker using the mouse", async function (assert) {
    await visit("/t/internationalization-localization/280");
    await click("#topic-footer-buttons .btn.create");

    await simulateKeys(".d-editor-input", "a :man_");
    // the 6th item in the list is the "more..."
    await click(".autocomplete.ac-emoji ul li:nth-of-type(6)");
    await emojiPicker().select("man_rowing_boat");

    assert
      .dom(".d-editor-preview")
      .hasHtml(
        `<p>a <img src="/images/emoji/twitter/man_rowing_boat.png?v=${v}" title=":man_rowing_boat:" class="emoji" alt=":man_rowing_boat:" loading="lazy" width="20" height="20" style="aspect-ratio: 20 / 20;"></p>`
      );
  });

  test("skin toned emoji is cooked properly", async function (assert) {
    await visit("/t/internationalization-localization/280");
    await click("#topic-footer-buttons .btn.create");

    await fillIn(".d-editor-input", "a :blonde_woman:t5:");

    assert
      .dom(".d-editor-preview")
      .hasHtml(
        `<p>a <img src="/images/emoji/twitter/blonde_woman/5.png?v=${v}" title=":blonde_woman:t5:" class="emoji" alt=":blonde_woman:t5:" loading="lazy" width="20" height="20" style="aspect-ratio: 20 / 20;"></p>`
      );
  });

  needs.settings({ emoji_autocomplete_min_chars: 2 });

  test("siteSetting:emoji_autocomplete_min_chars", async function (assert) {
    await visit("/t/internationalization-localization/280");
    await click("#topic-footer-buttons .btn.create");

    await simulateKeys(".d-editor-input", ":s");
    assert.dom(".autocomplete.ac-emoji").doesNotExist();

    await simulateKey(".d-editor-input", "w");
    assert.dom(".autocomplete.ac-emoji").exists();
  });
});
