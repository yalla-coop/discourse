import EmberObject, { computed } from "@ember/object";
import Mixin from "@ember/object/mixin";
import { isEmpty } from "@ember/utils";
import { i18n } from "discourse-i18n";

export default Mixin.create({
  rejectedPasswords: null,

  init() {
    this._super(...arguments);
    this.set("rejectedPasswords", []);
    this.set("rejectedPasswordsMessages", new Map());
  },

  passwordInstructions: computed("passwordMinLength", function () {
    return i18n("user.password.instructions", {
      count: this.passwordMinLength,
    });
  }),

  passwordMinLength: computed("isDeveloper", "admin", function () {
    const { isDeveloper, admin } = this;
    return isDeveloper || admin
      ? this.siteSettings.min_admin_password_length
      : this.siteSettings.min_password_length;
  }),

  passwordValidation: computed(
    "accountPassword",
    "passwordRequired",
    "rejectedPasswords.[]",
    "accountUsername",
    "accountName",
    "accountEmail",
    "passwordMinLength",
    "forceValidationReason",
    function () {
      const failedAttrs = {
        failed: true,
        ok: false,
        element: document.querySelector("#new-account-password"),
      };

      if (!this.passwordRequired) {
        return EmberObject.create({ ok: true });
      }

      if (this.rejectedPasswords.includes(this.accountPassword)) {
        return EmberObject.create(
          Object.assign(failedAttrs, {
            reason:
              this.rejectedPasswordsMessages.get(this.accountPassword) ||
              i18n("user.password.common"),
          })
        );
      }

      // If blank, fail without a reason
      if (isEmpty(this.accountPassword)) {
        return EmberObject.create(
          Object.assign(failedAttrs, {
            message: i18n("user.password.required"),
            reason: this.forceValidationReason
              ? i18n("user.password.required")
              : null,
          })
        );
      }

      // If too short
      if (this.accountPassword.length < this.passwordMinLength) {
        return EmberObject.create(
          Object.assign(failedAttrs, {
            reason: i18n("user.password.too_short", {
              count: this.passwordMinLength,
            }),
          })
        );
      }

      if (
        !isEmpty(this.accountUsername) &&
        this.accountPassword === this.accountUsername
      ) {
        return EmberObject.create(
          Object.assign(failedAttrs, {
            reason: i18n("user.password.same_as_username"),
          })
        );
      }

      if (
        !isEmpty(this.accountName) &&
        this.accountPassword === this.accountName
      ) {
        return EmberObject.create(
          Object.assign(failedAttrs, {
            reason: i18n("user.password.same_as_name"),
          })
        );
      }

      if (
        !isEmpty(this.accountEmail) &&
        this.accountPassword === this.accountEmail
      ) {
        return EmberObject.create(
          Object.assign(failedAttrs, {
            reason: i18n("user.password.same_as_email"),
          })
        );
      }

      // Looks good!
      return EmberObject.create({
        ok: true,
        reason: i18n("user.password.ok"),
      });
    }
  ),
});
