import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import AceEditor from "discourse/components/ace-editor";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";

module("Integration | Component | ace-editor", function (hooks) {
  setupRenderingTest(hooks);

  test("css editor", async function (assert) {
    await render(<template>
      <AceEditor @mode="css" style="width: 300px; height: 200px" />
    </template>);
    assert.dom(".ace_editor").exists("it renders the ace editor");
  });

  test("html editor", async function (assert) {
    await render(<template>
      <AceEditor
        @mode="html"
        @content="<b>wat</b>"
        style="width: 300px; height: 200px"
      />
    </template>);
    assert.dom(".ace_editor").exists("it renders the ace editor");
  });

  test("sql editor", async function (assert) {
    await render(<template>
      <AceEditor
        @mode="sql"
        @content="SELECT * FROM users"
        style="width: 300px; height: 200px"
      />
    </template>);
    assert.dom(".ace_editor").exists("it renders the ace editor");
  });

  test("yaml editor", async function (assert) {
    await render(<template>
      <AceEditor
        @mode="yaml"
        @content="test: true"
        style="width: 300px; height: 200px"
      />
    </template>);
    assert.dom(".ace_editor").exists("it renders the ace editor");
  });

  test("javascript editor", async function (assert) {
    await render(<template>
      <AceEditor
        @mode="javascript"
        @content="test: true"
        style="width: 300px; height: 200px"
      />
    </template>);
    assert.dom(".ace_editor").exists("it renders the ace editor");
  });

  test("disabled editor", async function (assert) {
    await render(<template>
      <AceEditor
        @mode="sql"
        @content="SELECT * FROM users"
        @disabled={{true}}
        style="width: 300px; height: 200px"
      />
    </template>);

    assert.dom(".ace_editor").exists("it renders the ace editor");
    assert
      .dom(".ace-wrapper")
      .hasAttribute("data-disabled", "true", "it has a data-disabled attr");
  });
});
