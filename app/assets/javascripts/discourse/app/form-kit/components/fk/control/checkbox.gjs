import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";
import { eq } from "truth-helpers";
import FKLabel from "discourse/form-kit/components/fk/label";

export default class FKControlCheckbox extends Component {
  static controlType = "checkbox";

  @action
  handleInput() {
    this.args.field.set(!this.args.value);
  }

  <template>
    <FKLabel class="form-kit__control-checkbox-label">
      <input
        type="checkbox"
        checked={{eq @value true}}
        class="form-kit__control-checkbox"
        disabled={{@field.disabled}}
        ...attributes
        {{on "change" this.handleInput}}
      />
      <span>{{yield}}</span>
    </FKLabel>
  </template>
}
