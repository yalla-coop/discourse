import UserLink from "discourse/components/user-link";
import avatar from "discourse/helpers/avatar";
import icon from "discourse-common/helpers/d-icon";

const ReviewableCreatedBy = <template>
  <div class="created-by">
    {{#if @user}}
      <UserLink @user={{@user}}>{{avatar @user imageSize="large"}}</UserLink>
    {{else}}
      {{icon "far-trash-alt" class="deleted-user-avatar"}}
    {{/if}}
  </div>
</template>;

export default ReviewableCreatedBy;
