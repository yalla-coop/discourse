import { classNames } from "@ember-decorators/component";
import ComboBoxComponent from "select-kit/components/combo-box";
import {
  pluginApiIdentifiers,
  selectKitOptions,
} from "select-kit/components/select-kit";

@classNames("timezone-input")
@selectKitOptions({
  filterable: true,
  allowAny: false,
})
@pluginApiIdentifiers("timezone-input")
export default class TimezoneInput extends ComboBoxComponent {
  get nameProperty() {
    return this.isLocalized ? "name" : null;
  }

  get valueProperty() {
    return this.isLocalized ? "value" : null;
  }

  get content() {
    return this.isLocalized ? moment.tz.localizedNames() : moment.tz.names();
  }

  get isLocalized() {
    return (
      moment.locale() !== "en" && typeof moment.tz.localizedNames === "function"
    );
  }
}
