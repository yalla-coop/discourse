import { click, currentRouteName, visit } from "@ember/test-helpers";
import { test } from "qunit";
import { GROUP_SMTP_SSL_MODES } from "discourse/lib/constants";
import formKit from "discourse/tests/helpers/form-kit-helper";
import {
  acceptance,
  exists,
  query,
} from "discourse/tests/helpers/qunit-helpers";
import selectKit from "discourse/tests/helpers/select-kit-helper";
import I18n from "discourse-i18n";

acceptance("Managing Group Email Settings - SMTP Disabled", function (needs) {
  needs.user();

  test("When SiteSetting.enable_smtp is false", async function (assert) {
    await visit("/g/discourse/manage/email");
    assert.notOk(
      query(".user-secondary-navigation").innerText.includes("Email"),
      "email link is not shown in the sidebar"
    );
    assert.strictEqual(
      currentRouteName(),
      "group.manage.profile",
      "it redirects to the group profile page"
    );
  });
});

acceptance(
  "Managing Group Email Settings - SMTP Enabled, IMAP Disabled",
  function (needs) {
    needs.user();
    needs.settings({ enable_smtp: true });

    test("When SiteSetting.enable_smtp is true but SiteSetting.enable_imap is false", async function (assert) {
      await visit("/g/discourse/manage/email");
      assert.ok(
        query(".user-secondary-navigation").innerText.includes("Email"),
        "email link is shown in the sidebar"
      );
      assert.strictEqual(
        currentRouteName(),
        "group.manage.email",
        "it redirects to the group email page"
      );
      assert.notOk(
        exists(".group-manage-email-imap-wrapper"),
        "does not show IMAP settings"
      );
    });
  }
);

acceptance(
  "Managing Group Email Settings - SMTP and IMAP Enabled",
  function (needs) {
    needs.user();
    needs.settings({ enable_smtp: true, enable_imap: true });

    needs.pretender((server, helper) => {
      server.post("/groups/47/test_email_settings", () => {
        return helper.response({
          success: "OK",
        });
      });
      server.put("/groups/47", () => {
        return helper.response({
          success: "OK",
        });
      });
    });

    test("enabling SMTP, testing, and saving", async function (assert) {
      await visit("/g/discourse/manage/email");
      assert.ok(
        query(".user-secondary-navigation").innerText.includes("Email"),
        "email link is shown in the sidebar"
      );
      assert.ok(
        exists("#enable_imap:disabled"),
        "IMAP is disabled until SMTP settings are valid"
      );

      await click("#enable_smtp");
      assert.ok(exists(".group-smtp-email-settings"));

      await click("#prefill_smtp_gmail");
      assert
        .form()
        .field("smtp_server")
        .hasValue("smtp.gmail.com", "prefills SMTP server settings for gmail");
      assert
        .form()
        .field("smtp_port")
        .hasValue("587", "prefills SMTP port settings for gmail");
      assert
        .form()
        .field("smtp_ssl_mode")
        .hasValue(
          GROUP_SMTP_SSL_MODES.starttls.toString(),
          "prefills SSL mode to STARTTLS for gmail"
        );

      await formKit().submit();
      assert.form().hasErrors(
        {
          [I18n.t("groups.manage.email.credentials.username")]: "Required",
          [I18n.t("groups.manage.email.credentials.password")]: "Required",
        },
        "does not allow testing settings if not all fields are filled"
      );

      await formKit().field("email_username").fillIn("myusername@gmail.com");
      await formKit().field("email_password").fillIn("password");
      await formKit()
        .field("email_from_alias")
        .fillIn("akasomegroup@example.com");

      await formKit().submit();
      await click(".group-manage-save");

      assert.strictEqual(
        query(".group-manage-save-button > span").innerText,
        "Saved!"
      );

      assert.notOk(
        exists("#enable_imap:disabled"),
        "IMAP is able to be enabled now that SMTP is saved"
      );

      await click("#enable_smtp");
      assert.strictEqual(
        query(".dialog-body").innerText.trim(),
        I18n.t("groups.manage.email.smtp_disable_confirm"),
        "shows a confirm dialogue warning SMTP settings will be wiped"
      );

      await click(".dialog-footer .btn-primary");
    });

    test("enabling IMAP, testing, and saving", async function (assert) {
      await visit("/g/discourse/manage/email");

      await click("#enable_smtp");
      await click("#prefill_smtp_gmail");
      await formKit().field("email_username").fillIn("myusername@gmail.com");
      await formKit().field("email_password").fillIn("password");
      await formKit().submit();
      await click(".group-manage-save");

      assert.notOk(
        exists("#enable_imap:disabled"),
        "IMAP is able to be enabled now that IMAP is saved"
      );

      await click("#enable_imap");

      assert.ok(
        exists(".test-imap-settings:disabled"),
        "does not allow testing settings if not all fields are filled"
      );

      await click("#prefill_imap_gmail");
      assert.strictEqual(
        query("input[name='imap_server']").value,
        "imap.gmail.com",
        "prefills IMAP server settings for gmail"
      );
      assert.strictEqual(
        query("input[name='imap_port']").value,
        "993",
        "prefills IMAP port settings for gmail"
      );
      assert.ok(
        exists("#enable_ssl_imap:checked"),
        "prefills IMAP ssl settings for gmail"
      );
      await click(".test-imap-settings");

      assert.ok(exists(".imap-settings-ok"), "tested settings are ok");

      await click(".group-manage-save");

      assert.strictEqual(
        query(".group-manage-save-button > span").innerText,
        "Saved!"
      );

      assert.ok(
        exists(".imap-no-mailbox-selected"),
        "shows a message saying no IMAP mailbox is selected"
      );

      await selectKit(
        ".control-group.group-imap-mailboxes .combo-box"
      ).expand();
      await selectKit(
        ".control-group.group-imap-mailboxes .combo-box"
      ).selectRowByValue("All Mail");
      await click(".group-manage-save");

      assert.notOk(
        exists(".imap-no-mailbox-selected"),
        "no longer shows a no mailbox selected message"
      );

      await click("#enable_imap");
      assert.strictEqual(
        query(".dialog-body").innerText.trim(),
        I18n.t("groups.manage.email.imap_disable_confirm"),
        "shows a confirm dialogue warning IMAP settings will be wiped"
      );
      await click(".dialog-footer .btn-primary");
    });
  }
);

acceptance(
  "Managing Group Email Settings - SMTP and IMAP Enabled - Settings Preflled",
  function (needs) {
    needs.user();
    needs.settings({ enable_smtp: true, enable_imap: true });

    needs.pretender((server, helper) => {
      server.get("/groups/discourse.json", () => {
        return helper.response(200, {
          group: {
            id: 47,
            automatic: false,
            name: "discourse",
            full_name: "Awesome Team",
            user_count: 8,
            alias_level: 99,
            visible: true,
            public_admission: true,
            public_exit: false,
            flair_url: "fa-adjust",
            is_group_owner: true,
            mentionable: true,
            messageable: true,
            can_see_members: true,
            has_messages: true,
            message_count: 2,
            smtp_server: "smtp.gmail.com",
            smtp_port: 587,
            smtp_ssl_mode: GROUP_SMTP_SSL_MODES.starttls,
            smtp_enabled: true,
            smtp_updated_at: "2021-06-16T02:58:12.739Z",
            smtp_updated_by: {
              id: 19,
              username: "eviltrout",
              name: "Robin Ward",
              avatar_template:
                "/letter_avatar/eviltrout/{size}/3_f9720745f5ce6dfc2b5641fca999d934.png",
            },
            imap_server: "imap.gmail.com",
            imap_port: 993,
            imap_ssl: true,
            imap_mailbox_name: "INBOX",
            imap_mailboxes: ["INBOX", "[Gmail]/All Mail", "[Gmail]/Important"],
            imap_enabled: true,
            imap_updated_at: "2021-06-16T02:58:12.738Z",
            imap_updated_by: {
              id: 19,
              username: "eviltrout",
              name: "Robin Ward",
              avatar_template:
                "/letter_avatar/eviltrout/{size}/3_f9720745f5ce6dfc2b5641fca999d934.png",
            },
            email_username: "test@test.com",
            email_password: "password",
          },
          extras: {
            visible_group_names: ["discourse"],
          },
        });
      });
    });

    test("prefills smtp and imap saved settings and shows last updated details", async function (assert) {
      await visit("/g/discourse/manage/email");

      assert.notOk(exists("#enable_smtp:disabled"), "SMTP is not disabled");
      assert.notOk(exists("#enable_imap:disabled"), "IMAP is not disabled");

      assert
        .form()
        .field("email_username")
        .hasValue("test@test.com", "email username is prefilled");
      assert
        .form()
        .field("email_password")
        .hasValue("password", "email password is prefilled");
      assert
        .form()
        .field("smtp_server")
        .hasValue("smtp.gmail.com", "SMTP server is prefilled");
      assert
        .form()
        .field("smtp_port")
        .hasValue("587", "SMTP port is prefilled");
      assert
        .form()
        .field("smtp_ssl_mode")
        .hasValue(
          GROUP_SMTP_SSL_MODES.starttls.toString(),
          "SMTP ssl mode is prefilled"
        );

      assert.strictEqual(
        query("[name='imap_server']").value,
        "imap.gmail.com",
        "imap server is prefilled"
      );
      assert.strictEqual(
        query("[name='imap_port']").value,
        "993",
        "imap port is prefilled"
      );
      assert.strictEqual(
        selectKit("#imap_mailbox").header().value(),
        "INBOX",
        "imap mailbox is prefilled"
      );

      const regex = /updated: (.*?) by eviltrout/;
      assert.ok(exists(".group-email-last-updated-details.for-imap"));
      assert.ok(
        regex.test(
          query(".group-email-last-updated-details.for-imap").innerText.trim()
        ),
        "shows last updated imap details"
      );
    });
  }
);

acceptance(
  "Managing Group Email Settings - SMTP and IMAP Enabled - Email Test Invalid",
  function (needs) {
    needs.user();
    needs.settings({ enable_smtp: true, enable_imap: true });

    needs.pretender((server, helper) => {
      server.post("/groups/47/test_email_settings", () => {
        return helper.response(422, {
          success: false,
          errors: [
            "There was an issue with the SMTP credentials provided, check the username and password and try again.",
          ],
        });
      });
    });

    test("enabling IMAP, testing, and saving", async function (assert) {
      await visit("/g/discourse/manage/email");

      await click("#enable_smtp");
      await click("#prefill_smtp_gmail");
      await formKit().field("email_username").fillIn("myusername@gmail.com");
      await formKit().field("email_password").fillIn("password");
      await formKit().submit();

      assert.strictEqual(
        query(".dialog-body").innerText.trim(),
        I18n.t("generic_error_with_reason", {
          error:
            "There was an issue with the SMTP credentials provided, check the username and password and try again.",
        })
      );
      await click(".dialog-footer .btn-primary");
    });
  }
);
