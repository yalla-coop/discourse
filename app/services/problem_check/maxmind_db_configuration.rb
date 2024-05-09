# frozen_string_literal: true

class ProblemCheck::MaxmindDbConfiguration < ProblemCheck
  self.priority = "low"

  def call
    if GlobalSetting.maxmind_license_key.present? && GlobalSetting.maxmind_account_id.blank?
      problem
    else
      no_problem
    end
  end

  private

  def translation_key
    "dashboard.maxmind_db_configuration_warning"
  end
end
