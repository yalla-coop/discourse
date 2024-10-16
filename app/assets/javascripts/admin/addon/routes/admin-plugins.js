import { service } from "@ember/service";
import DiscourseRoute from "discourse/routes/discourse";
import I18n from "discourse-i18n";
import AdminPlugin from "admin/models/admin-plugin";

export default class AdminPluginsRoute extends DiscourseRoute {
  @service router;

  async model() {
    const plugins = await this.store.findAll("plugin");
    return plugins.map((plugin) => AdminPlugin.create(plugin));
  }

  titleToken() {
    return I18n.t("admin.plugins.title");
  }
}
