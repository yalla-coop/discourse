import EmberObject from "@ember/object";
import { click, render } from "@ember/test-helpers";
import { TrackedObject } from "@ember-compat/tracked-built-ins";
import hbs from "htmlbars-inline-precompile";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import I18n from "discourse-i18n";

let requests = 0;

module("Poll | Component | poll", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    pretender.put("/polls/vote", () => {
      ++requests;
      return response({
        poll: {
          name: "poll",
          type: "regular",
          status: "open",
          results: "always",
          options: [
            {
              id: "1f972d1df351de3ce35a787c89faad29",
              html: "yes",
              votes: 1,
            },
            {
              id: "d7ebc3a9beea2e680815a1e4f57d6db6",
              html: "no",
              votes: 0,
            },
          ],
          voters: 1,
          chart_type: "bar",
        },
        vote: ["1f972d1df351de3ce35a787c89faad29"],
      });
    });
  });

  test("shows vote", async function (assert) {
    this.setProperties({
      post: EmberObject.create({
        id: 42,
        topic: {
          archived: false,
        },
        user_id: 29,
      }),
      poll: new TrackedObject({
        name: "poll",
        type: "regular",
        status: "closed",
        results: "always",
        options: [
          { id: "1f972d1df351de3ce35a787c89faad29", html: "yes", votes: 1 },
          { id: "d7ebc3a9beea2e680815a1e4f57d6db6", html: "no", votes: 0 },
        ],
        voters: 1,
        chart_type: "bar",
      }),
    });

    await render(hbs`<Poll @post={{this.post}} @poll={{this.poll}} />`);

    assert.dom(".results li:nth-of-type(1) .option p").hasText("100% yes");
    assert.dom(".results li:nth-of-type(2) .option p").hasText("0% no");
  });

  test("does not show results after voting when results are to be shown only on closed", async function (assert) {
    this.setProperties({
      post: EmberObject.create({
        id: 42,
        topic: {
          archived: false,
        },
        user_id: 29,
      }),
      poll: new TrackedObject({
        name: "poll",
        type: "regular",
        status: "open",
        results: "on_close",
        options: [
          { id: "1f972d1df351de3ce35a787c89faad29", html: "yes" },
          { id: "d7ebc3a9beea2e680815a1e4f57d6db6", html: "no" },
        ],
        voters: 1,
        chart_type: "bar",
      }),
    });

    await render(hbs`<Poll @post={{this.post}} @poll={{this.poll}} />`);

    assert.dom("ul.options").exists("options are shown");
    assert.dom("ul.results").doesNotExist("results are not shown");
  });

  test("can vote", async function (assert) {
    this.setProperties({
      post: EmberObject.create({
        id: 42,
        topic: {
          archived: false,
        },
        user_id: 29,
      }),
      poll: new TrackedObject({
        name: "poll",
        type: "regular",
        status: "open",
        results: "always",
        options: [
          { id: "1f972d1df351de3ce35a787c89faad29", html: "yes", votes: 0 },
          { id: "d7ebc3a9beea2e680815a1e4f57d6db6", html: "no", votes: 0 },
        ],
        voters: 0,
        chart_type: "bar",
      }),
    });

    await render(hbs`<Poll @post={{this.post}} @poll={{this.poll}} />`);

    requests = 0;

    await click(
      "li[data-poll-option-id='1f972d1df351de3ce35a787c89faad29'] button"
    );
    assert.strictEqual(requests, 1);
    assert.dom(".chosen").exists({ count: 1 });

    await click(".toggle-results");
    assert
      .dom("li[data-poll-option-id='1f972d1df351de3ce35a787c89faad29']")
      .exists({ count: 1 });
  });

  test("cannot vote if not member of the right group", async function (assert) {
    this.setProperties({
      post: EmberObject.create({
        id: 42,
        topic: {
          archived: false,
        },
        user_id: 29,
      }),
      poll: new TrackedObject({
        name: "poll",
        type: "regular",
        status: "open",
        results: "always",
        options: [
          { id: "1f972d1df351de3ce35a787c89faad29", html: "yes", votes: 0 },
          { id: "d7ebc3a9beea2e680815a1e4f57d6db6", html: "no", votes: 0 },
        ],
        voters: 0,
        chart_type: "bar",
        groups: "foo",
      }),
    });

    await render(hbs`<Poll @post={{this.post}} @poll={{this.poll}} />`);

    requests = 0;

    await click(
      "li[data-poll-option-id='1f972d1df351de3ce35a787c89faad29'] button"
    );
    assert
      .dom(".poll-container .alert")
      .hasText(I18n.t("poll.results.groups.title", { groups: "foo" }));
    assert.strictEqual(requests, 0);
    assert.dom(".chosen").doesNotExist();
  });

  test("voting on a multiple poll with no min attribute", async function (assert) {
    this.setProperties({
      post: EmberObject.create({
        id: 42,
        topic: {
          archived: false,
        },
        user_id: 29,
      }),
      poll: EmberObject.create({
        name: "poll",
        type: "multiple",
        status: "open",
        results: "always",
        max: 2,
        options: [
          { id: "1f972d1df351de3ce35a787c89faad29", html: "yes", votes: 0 },
          { id: "d7ebc3a9beea2e680815a1e4f57d6db6", html: "no", votes: 0 },
        ],
        voters: 0,
        chart_type: "bar",
      }),
    });
    await render(hbs`<Poll @post={{this.post}} @poll={{this.poll}} />`);

    assert.dom(".poll-buttons .cast-votes:disabled").exists();

    await click(
      "li[data-poll-option-id='1f972d1df351de3ce35a787c89faad29'] button"
    );

    await click(".poll-buttons .cast-votes");
    assert.dom(".chosen").exists();
  });
});
