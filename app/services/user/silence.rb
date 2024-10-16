# frozen_string_literal: true

class User::Silence
  include Service::Base

  contract do
    attribute :user_id, :integer
    attribute :reason, :string
    attribute :message, :string
    attribute :silenced_till, :datetime
    attribute :other_user_ids, :array
    attribute :post_id, :integer
    attribute :post_action, :string
    attribute :post_edit, :string

    validates :user_id, presence: true
    validates :reason, presence: true, length: { maximum: 300 }
    validates :silenced_till, presence: true
    validates :other_user_ids, length: { maximum: User::MAX_SIMILAR_USERS }
    validates :post_action, inclusion: { in: %w[delete delete_replies edit] }, allow_blank: true
  end
  model :user
  policy :not_silenced_already, class_name: User::Policy::NotAlreadySilenced
  model :users
  policy :can_silence_all_users
  step :silence
  model :post, optional: true
  step :perform_post_action

  private

  def fetch_user(contract:)
    User.find_by(id: contract.user_id)
  end

  def fetch_users(user:, contract:)
    [user, *User.where(id: contract.other_user_ids.to_a.uniq).to_a]
  end

  def can_silence_all_users(guardian:, users:)
    users.all? { guardian.can_silence_user?(_1) }
  end

  def silence(guardian:, users:, contract:)
    context[:full_reason] = User::Action::SilenceAll.call(users:, actor: guardian.user, contract:)
  end

  def fetch_post(contract:)
    Post.find_by(id: contract.post_id)
  end

  def perform_post_action(guardian:, post:, contract:)
    User::Action::TriggerPostAction.call(guardian:, post:, contract:)
  end
end
