import Component from "@ember/component";
import { equal } from "@ember/object/computed";
import { classNameBindings } from "@ember-decorators/component";

export default class EditCategoryPanel extends Component {}

export function buildCategoryPanel(tab) {
  @classNameBindings(
    ":edit-category-tab",
    "activeTab::hide",
    `:edit-category-tab-${tab}`
  )
  class BuiltCategoryPanel extends EditCategoryPanel {
    @equal("selectedTab", tab) activeTab;
  }
  return BuiltCategoryPanel;
}
