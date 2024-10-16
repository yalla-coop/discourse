import EmberObject from "@ember/object";
import discourseComputed from "discourse-common/utils/decorators";

export default class VisitedLine extends EmberObject {
  @discourseComputed
  isLastVisited() {
    return this.lastVisitedTopic === this.topic;
  }
}
