import { render } from "@ember/test-helpers";
import { module, test } from "qunit";
import Form from "discourse/components/form";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import formKit from "discourse/tests/helpers/form-kit-helper";

module(
  "Integration | Component | FormKit | Controls | Select",
  function (hooks) {
    setupRenderingTest(hooks);

    test("default", async function (assert) {
      let data = { foo: "option-2" };
      const mutateData = (x) => (data = x);

      await render(<template>
        <Form @onSubmit={{mutateData}} @data={{data}} as |form|>
          <form.Field @name="foo" @title="Foo" as |field|>
            <field.Select as |select|>
              <select.Option @value="option-1">Option 1</select.Option>
              <select.Option @value="option-2">Option 2</select.Option>
              <select.Option @value="option-3">Option 3</select.Option>
            </field.Select>
          </form.Field>
        </Form>
      </template>);

      assert.deepEqual(data, { foo: "option-2" });
      assert.form().field("foo").hasValue("option-2");

      await formKit().field("foo").select("option-3");

      assert.form().field("foo").hasValue("option-3");

      await formKit().submit();

      assert.deepEqual(data, { foo: "option-3" });
    });
  }
);
