import Component from "@glimmer/component";
import { concat } from "@ember/helper";
import { action } from "@ember/object";
import FKLabel from "discourse/form-kit/components/fk/label";
import FKMeta from "discourse/form-kit/components/fk/meta";
import FormText from "discourse/form-kit/components/fk/text";
import concatClass from "discourse/helpers/concat-class";
import i18n from "discourse-common/helpers/i18n";

export default class FKControlWrapper extends Component {
  constructor() {
    super(...arguments);

    this.args.field.setType(this.controlType);
  }

  get controlType() {
    if (this.args.component.controlType === "input") {
      return this.args.component.controlType + "-" + (this.args.type || "text");
    }

    return this.args.component.controlType;
  }

  @action
  setFieldType() {
    this.args.field.type = this.controlType;
  }

  get error() {
    return (this.args.errors ?? {})[this.args.field.name];
  }

  normalizeName(name) {
    return name.replace(/\./g, "-");
  }

  <template>
    <div
      id={{concat "control-" (this.normalizeName @field.name)}}
      class={{concatClass
        "form-kit__container"
        "form-kit__field"
        (concat "form-kit__field-" this.controlType)
        (if this.error "has-error")
      }}
      data-disabled={{@field.disabled}}
      data-name={{@field.name}}
      data-control-type={{this.controlType}}
    >
      {{#if @field.showTitle}}
        <FKLabel class="form-kit__container-title" @fieldId={{@field.id}}>
          {{@field.title}}

          {{#unless @field.required}}
            <span class="form-kit__container-optional">({{i18n
                "form_kit.optional"
              }})</span>
          {{/unless}}
        </FKLabel>
      {{/if}}

      {{#if @field.subtitle}}
        <FormText
          class="form-kit__container-subtitle"
        >{{@field.subtitle}}</FormText>
      {{/if}}

      <div
        class={{concatClass
          "form-kit__container-content"
          (if @format (concat "--" @format))
        }}
      >
        <@component
          @field={{@field}}
          @value={{@value}}
          @type={{@type}}
          @yesLabel={{@yesLabel}}
          @noLabel={{@noLabel}}
          @lang={{@lang}}
          @before={{@before}}
          @after={{@after}}
          @height={{@height}}
          @selection={{@selection}}
          id={{@field.id}}
          name={{@field.name}}
          aria-invalid={{if this.error "true"}}
          aria-describedby={{if this.error @field.errorId}}
          ...attributes
          as |components|
        >
          {{yield components}}
        </@component>

        <FKMeta
          @description={{@field.description}}
          @value={{@value}}
          @field={{@field}}
          @error={{this.error}}
        />
      </div>
    </div>
  </template>
}
