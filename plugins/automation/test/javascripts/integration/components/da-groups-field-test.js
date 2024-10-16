import { getOwner } from "@ember/owner";
import { render } from "@ember/test-helpers";
import { hbs } from "ember-cli-htmlbars";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import pretender, { response } from "discourse/tests/helpers/create-pretender";
import selectKit from "discourse/tests/helpers/select-kit-helper";
import AutomationFabricators from "discourse/plugins/automation/admin/lib/fabricators";

module("Integration | Component | da-groups-field", function (hooks) {
  setupRenderingTest(hooks);

  hooks.beforeEach(function () {
    this.automation = new AutomationFabricators(getOwner(this)).automation();

    pretender.get("/groups/search.json", () => {
      return response([
        {
          id: 1,
          name: "cats",
          flair_url: "fa-bars",
          flair_bg_color: "CC000A",
          flair_color: "FFFFFA",
        },
        {
          id: 2,
          name: "dogs",
          flair_url: "fa-bars",
          flair_bg_color: "CC000A",
          flair_color: "FFFFFA",
        },
      ]);
    });
  });

  test("set value", async function (assert) {
    this.field = new AutomationFabricators(getOwner(this)).field({
      component: "groups",
    });

    await render(
      hbs`<AutomationField @automation={{this.automation}} @field={{this.field}} />`
    );

    await selectKit().expand();
    await selectKit().selectRowByValue(1);

    assert.deepEqual(this.field.metadata.value, [1]);
  });

  test("supports a maxmimum value", async function (assert) {
    this.field = new AutomationFabricators(getOwner(this)).field({
      component: "groups",
      extra: { maximum: 1 },
    });

    await render(
      hbs`<AutomationField @automation={{this.automation}} @field={{this.field}} />`
    );

    await selectKit().expand();
    await selectKit().selectRowByValue(1);

    assert.deepEqual(this.field.metadata.value, [1]);

    await selectKit().expand();
    await selectKit().selectRowByValue(2);

    assert.deepEqual(this.field.metadata.value, [2]);
  });
});
