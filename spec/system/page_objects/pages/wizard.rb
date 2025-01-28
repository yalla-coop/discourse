# frozen_string_literal: true

module PageObjects
  module Pages
    class Wizard < PageObjects::Pages::Base
      attr_reader :introduction_step,
                  :privacy_step,
                  :ready_step,
                  :branding_step,
                  :styling_step,
                  :corporate_step

      def initialize
        @introduction_step = PageObjects::Pages::Wizard::IntroductionStep.new(self)
        @privacy_step = PageObjects::Pages::Wizard::PrivacyStep.new(self)
        @ready_step = PageObjects::Pages::Wizard::ReadyStep.new(self)
        @branding_step = PageObjects::Pages::Wizard::BrandingStep.new(self)
        @styling_step = PageObjects::Pages::Wizard::StylingStep.new(self)
        @corporate_step = PageObjects::Pages::Wizard::CorporateStep.new(self)
      end

      def go_to_step(step_id)
        visit("/wizard/steps/#{step_id}")
      end

      def on_step?(step_id)
        has_css?(".wizard-container__step.#{step_id}")
      end

      def click_jump_in
        find(".wizard-container__button.jump-in").click
      end

      def click_configure_more
        find(".wizard-container__button.configure-more").click
      end

      def go_to_next_step
        find(".wizard-container__button.next").click
      end

      def find_field(field_type, field_id)
        find(".wizard-container__field.#{field_type}-field.#{field_type}-#{field_id}")
      end

      def fill_field(field_type, field_id, value)
        find_field(field_type, field_id).fill_in(with: value)
      end

      def has_field_with_value?(field_type, field_id, value)
        find_field(field_type, field_id).find("input").value == value
      end
    end
  end
end

class PageObjects::Pages::Wizard::StepBase < PageObjects::Pages::Base
  attr_reader :wizard

  def initialize(wizard)
    @wizard = wizard
  end
end

class PageObjects::Pages::Wizard::IntroductionStep < PageObjects::Pages::Wizard::StepBase
end

class PageObjects::Pages::Wizard::PrivacyStep < PageObjects::Pages::Wizard::StepBase
  def choice_selector(choice_id)
    ".wizard-container__radio-choice[data-choice-id='#{choice_id}']"
  end

  def select_access_option(section, choice_id)
    wizard.find_field("radio", section).find(choice_selector(choice_id)).click
  end

  def has_selected_choice?(section, choice_id)
    wizard.find_field("radio", section).has_css?(choice_selector(choice_id) + ".--selected")
  end
end

class PageObjects::Pages::Wizard::ReadyStep < PageObjects::Pages::Wizard::StepBase
end

class PageObjects::Pages::Wizard::BrandingStep < PageObjects::Pages::Wizard::StepBase
  def click_upload_button(field_id)
    wizard.find_field("image", field_id).find(".wizard-container__button-upload").click
  end

  def has_upload?(field_id)
    wizard.find_field("image", field_id).has_css?(".wizard-container__button-upload.has-upload")
  end
end

class PageObjects::Pages::Wizard::StylingStep < PageObjects::Pages::Wizard::StepBase
  def select_color_palette_option(palette)
    select_kit =
      PageObjects::Components::SelectKit.new(".dropdown-color-scheme .wizard-container__dropdown")
    select_kit.expand
    select_kit.select_row_by_value(palette)
  end

  def select_font_option(font)
    select_kit =
      PageObjects::Components::SelectKit.new(".dropdown-site-font .wizard-container__dropdown")
    select_kit.expand
    select_kit.select_row_by_value(font)
  end

  def select_body_font_option(font)
    select_kit =
      PageObjects::Components::SelectKit.new(".dropdown-body-font .wizard-container__dropdown")
    select_kit.expand
    select_kit.select_row_by_value(font)
  end

  def select_heading_font_option(font)
    select_kit =
      PageObjects::Components::SelectKit.new(".dropdown-heading-font .wizard-container__dropdown")
    select_kit.expand
    select_kit.select_row_by_value(font)
  end

  def select_homepage_style_option(homepage)
    select_kit =
      PageObjects::Components::SelectKit.new(".dropdown-homepage-style .wizard-container__dropdown")
    select_kit.expand
    select_kit.select_row_by_value(homepage)
  end

  def has_selected_color_palette?(palette)
    select_kit =
      PageObjects::Components::SelectKit.new(".dropdown-color-scheme .wizard-container__dropdown")
    select_kit.has_selected_value?(palette)
  end

  def has_selected_font?(font)
    select_kit =
      PageObjects::Components::SelectKit.new(".dropdown-site-font .wizard-container__dropdown")
    select_kit.has_selected_value?(font)
  end

  def has_selected_body_font?(font)
    select_kit =
      PageObjects::Components::SelectKit.new(".dropdown-body-font .wizard-container__dropdown")
    select_kit.has_selected_value?(font)
  end

  def has_selected_heading_font?(font)
    select_kit =
      PageObjects::Components::SelectKit.new(".dropdown-heading-font .wizard-container__dropdown")
    select_kit.has_selected_value?(font)
  end

  def has_selected_homepage_style?(hompage)
    select_kit =
      PageObjects::Components::SelectKit.new(".dropdown-homepage-style .wizard-container__dropdown")
    select_kit.has_selected_value?(hompage)
  end
end

class PageObjects::Pages::Wizard::CorporateStep < PageObjects::Pages::Wizard::StepBase
end
