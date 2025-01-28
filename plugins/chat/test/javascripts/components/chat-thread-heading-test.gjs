import { getOwner } from "@ember/owner";
import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import ChatThreadHeading from "discourse/plugins/chat/discourse/components/chat-thread-heading";
import ChatFabricators from "discourse/plugins/chat/discourse/lib/fabricators";

module("Discourse Chat | Component | chat-thread-heading", function (hooks) {
  setupRenderingTest(hooks);

  test("it renders the title", async function (assert) {
    const thread = new ChatFabricators(getOwner(this)).thread({
      title: "A nice thread title",
    });

    await render(<template><ChatThreadHeading @thread={{thread}} /></template>);

    assert.dom(".chat-thread__heading-title").hasText("A nice thread title");
  });

  test("it doesn’t render heading when no title", async function (assert) {
    const thread = new ChatFabricators(getOwner(this)).thread({
      title: null,
    });

    await render(<template><ChatThreadHeading @thread={{thread}} /></template>);

    assert.dom(".chat-thread__heading").doesNotExist();
  });
});
