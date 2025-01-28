# frozen_string_literal: true

describe "Admin | Sidebar Navigation", type: :system do
  UNFILTERED_LINK_COUNT = 41

  fab!(:admin)
  fab!(:moderator)

  let(:sidebar) { PageObjects::Components::NavigationMenu::Sidebar.new }
  let(:sidebar_dropdown) { PageObjects::Components::SidebarHeaderDropdown.new }
  let(:filter) { PageObjects::Components::Filter.new }

  before do
    SiteSetting.navigation_menu = "sidebar"
    SiteSetting.admin_sidebar_enabled_groups = [
      Group::AUTO_GROUPS[:admins],
      Group::AUTO_GROUPS[:moderators],
    ]

    sign_in(admin)
  end

  it "shows the sidebar when navigating to an admin route and hides it when leaving" do
    visit("/latest")
    expect(sidebar).to have_section("categories")
    sidebar.click_link_in_section("community", "admin")
    expect(page).to have_current_path("/admin")
    expect(sidebar).to be_visible
    expect(sidebar).to have_no_section("categories")
    expect(page).to have_no_css(".admin-main-nav")
    filter.click_back_to_forum
    expect(page).to have_current_path("/")
    expect(sidebar).to have_no_section("admin-root")
  end

  context "with subfolder" do
    before { set_subfolder "/discuss" }

    it "navigates back to homepage correctly" do
      visit("/discuss/admin")

      filter.click_back_to_forum
      expect(page).to have_current_path("/discuss/")
    end
  end

  it "displays the panel header" do
    visit("/admin")
    expect(sidebar).to have_panel_header
  end

  it "collapses sections by default" do
    visit("/admin")
    links = page.all(".sidebar-section-link-content-text")
    expect(links.map(&:text)).to eq(
      [
        I18n.t("admin_js.admin.dashboard.title"),
        I18n.t("admin_js.admin.community.sidebar_link.users"),
        I18n.t("admin_js.admin.community.sidebar_link.groups"),
        I18n.t("admin_js.admin.advanced.sidebar_link.all_site_settings"),
        I18n.t("admin_js.admin.account.sidebar_link.whats_new.title"),
      ],
    )
  end

  context "when on mobile" do
    it "shows the admin sidebar links in the header-dropdown when navigating to an admin route and hides them when leaving",
       mobile: true do
      visit("/latest")
      sidebar_dropdown.click
      expect(sidebar).to have_section("community")
      sidebar.click_link_in_section("community", "admin")
      expect(page).to have_current_path("/admin")
      sidebar_dropdown.click
      expect(sidebar).to have_no_section("community")
      expect(page).to have_no_css(".admin-main-nav")
      filter.click_back_to_forum
      expect(page).to have_current_path("/")
      sidebar_dropdown.click
      expect(sidebar).to have_no_section("admin-root")
    end
  end

  context "when the setting is disabled" do
    before { SiteSetting.admin_sidebar_enabled_groups = "" }

    it "does not show the admin sidebar" do
      visit("/latest")
      sidebar.click_link_in_section("community", "admin")
      expect(page).to have_current_path("/admin")
      expect(sidebar).to have_no_section("admin-root")
    end
  end

  it "allows links to be filtered" do
    visit("/admin")
    sidebar.toggle_all_sections

    expect(page).to have_selector(
      ".sidebar-section-link-content-text",
      minimum: UNFILTERED_LINK_COUNT,
    )
    expect(page).to have_no_css(".sidebar-no-results")
    all_links_count = page.all(".sidebar-section-link-content-text").count

    filter.filter("ie")
    links = page.all(".sidebar-section-link-content-text")
    expect(links.map(&:text)).to eq(
      [
        I18n.t("admin_js.admin.community.sidebar_link.user_fields"),
        I18n.t("admin_js.admin.community.sidebar_link.moderation_flags.title"),
        I18n.t("admin_js.admin.email_settings.sidebar_link.server_setup.title"),
      ],
    )
    expect(page).to have_no_css(".sidebar-no-results")

    filter.filter("ieeee")
    expect(page).to have_no_css(".sidebar-section-link-content-text")
    expect(page).to have_css(".sidebar-no-results")

    filter.clear
    links = page.all(".sidebar-section-link-content-text")
    expect(links.count).to eq(all_links_count)
    expect(page).to have_no_css(".sidebar-no-results")
    expect(page).to have_css(".sidebar-sections__back-to-forum")

    # When match section title, display all links
    filter.filter("Email Sett")
    links = page.all(".sidebar-section-link-content-text")
    expect(links.map(&:text)).to eq(
      [
        I18n.t("admin_js.admin.email_settings.sidebar_link.server_setup.title"),
        I18n.t("admin_js.admin.email_settings.sidebar_link.appearance"),
      ],
    )
  end

  it "escapes the filtered expression for regex expressions" do
    visit("/admin")

    filter.filter(".*") # this shouldn't return any results if the expression was escaped
    expect(page).to have_no_css(".sidebar-section-link-content-text")
    expect(page).to have_css(".sidebar-no-results")
  end

  it "displays the no results description message correctly when the filter has no results" do
    visit("/admin")

    filter.filter("ieeee")
    expect(page).to have_no_css(".sidebar-section-link-content-text")
    expect(page).to have_css(".sidebar-no-results")

    no_results_description = page.find(".sidebar-no-results__description")
    expect(no_results_description.text).to eq(
      "We couldn’t find anything matching ‘ieeee’.\n\nDid you want to search site settings or the admin user list?",
    )
    expect(no_results_description).to have_link(
      "search site settings",
      href: "/admin/site_settings/category/all_results?filter=ieeee",
    )
    expect(no_results_description).to have_link(
      "admin user list?",
      href: "/admin/users/list/active?username=ieeee",
    )
  end

  it "encodes the url param in the links when the filter has no results" do
    visit("/admin")

    unknown_filter = "blahblah"
    filter.filter(unknown_filter)
    expect(page).to have_no_css(".sidebar-section-link-content-text")
    expect(page).to have_css(".sidebar-no-results")

    no_results_description = page.find(".sidebar-no-results__description")
    expect(no_results_description.text).to eq(
      "We couldn’t find anything matching ‘#{unknown_filter}’.\n\nDid you want to search site settings or the admin user list?",
    )
    expect(no_results_description).to have_link(
      "search site settings",
      href: "/admin/site_settings/category/all_results?filter=#{unknown_filter}",
    )
    expect(no_results_description).to have_link(
      "admin user list?",
      href: "/admin/users/list/active?username=#{unknown_filter}",
    )
  end

  it "temporarily expands section when filter" do
    visit("/admin")
    links = page.all(".sidebar-section-link-content-text")
    expect(links.map(&:text)).to eq(
      [
        I18n.t("admin_js.admin.dashboard.title"),
        I18n.t("admin_js.admin.community.sidebar_link.users"),
        I18n.t("admin_js.admin.community.sidebar_link.groups"),
        I18n.t("admin_js.admin.advanced.sidebar_link.all_site_settings"),
        I18n.t("admin_js.admin.account.sidebar_link.whats_new.title"),
      ],
    )

    filter.filter("ie")
    links = page.all(".sidebar-section-link-content-text")
    expect(links.map(&:text)).to eq(
      [
        I18n.t("admin_js.admin.community.sidebar_link.user_fields"),
        I18n.t("admin_js.admin.community.sidebar_link.moderation_flags.title"),
        I18n.t("admin_js.admin.email_settings.sidebar_link.server_setup.title"),
      ],
    )

    filter.filter("")
    links = page.all(".sidebar-section-link-content-text")
    expect(links.map(&:text)).to eq(
      [
        I18n.t("admin_js.admin.dashboard.title"),
        I18n.t("admin_js.admin.community.sidebar_link.users"),
        I18n.t("admin_js.admin.community.sidebar_link.groups"),
        I18n.t("admin_js.admin.advanced.sidebar_link.all_site_settings"),
        I18n.t("admin_js.admin.account.sidebar_link.whats_new.title"),
      ],
    )
  end

  it "allows further filtering of site settings or users if links do not show results" do
    user_1 = Fabricate(:user, username: "moltisanti", name: "Christopher Moltisanti")
    user_2 = Fabricate(:user, username: "bevelaqua", name: "Matthew Bevelaqua")

    visit("/admin")
    filter.filter("user locale")
    find(".sidebar-additional-filter-settings").click
    expect(page).to have_current_path(
      "/admin/site_settings/category/all_results?filter=user%20locale",
    )
    expect(page).to have_content(I18n.t("site_settings.allow_user_locale"))

    filter.filter("log_search_queries")
    find(".sidebar-additional-filter-settings").click
    expect(page).to have_current_path(
      "/admin/site_settings/category/all_results?filter=log_search_queries",
    )
    expect(page).to have_content(I18n.t("site_settings.log_search_queries"))

    filter.filter("bevelaqua")
    find(".sidebar-additional-filter-users").click
    expect(page).to have_current_path("/admin/users/list/active?username=bevelaqua")
    expect(find(".users-list-container")).to have_content("bevelaqua")

    filter.filter("moltisanti")
    find(".sidebar-additional-filter-users").click
    expect(page).to have_current_path("/admin/users/list/active?username=moltisanti")
    expect(find(".users-list-container")).to have_content("moltisanti")
  end

  it "allows sections to be expanded" do
    visit("/admin")
    sidebar.toggle_all_sections
    expect(page).to have_selector(
      ".sidebar-section-link-content-text",
      minimum: UNFILTERED_LINK_COUNT,
    )

    sidebar.toggle_all_sections
    expect(page).to have_selector(".sidebar-section-link-content-text", count: 5)
    expect(all(".sidebar-section-link-content-text").map(&:text)).to eq(
      [
        I18n.t("admin_js.admin.dashboard.title"),
        I18n.t("admin_js.admin.community.sidebar_link.users"),
        I18n.t("admin_js.admin.community.sidebar_link.groups"),
        I18n.t("admin_js.admin.advanced.sidebar_link.all_site_settings"),
        I18n.t("admin_js.admin.account.sidebar_link.whats_new.title"),
      ],
    )

    sidebar.toggle_all_sections
    expect(page).to have_selector(
      ".sidebar-section-link-content-text",
      minimum: UNFILTERED_LINK_COUNT,
    )
  end

  it "accepts hidden keywords like installed plugin names for filter" do
    Discourse.instance_variable_set(
      "@plugins",
      Plugin::Instance.find_all("#{Rails.root}/spec/fixtures/plugins"),
    )

    visit("/admin")
    sidebar.toggle_all_sections
    filter.filter("csp_extension")
    links = page.all(".sidebar-section-link-content-text")
    expect(links.count).to eq(1)
    expect(links.map(&:text)).to eq(["Installed"])
  end

  it "accepts components and themes keywords for filter" do
    Fabricate(:theme, name: "Air theme", component: false)
    Fabricate(:theme, name: "Kanban", component: true)

    visit("/admin")
    sidebar.toggle_all_sections

    filter.filter("air")
    links = page.all(".sidebar-section-link-content-text")
    expect(links.count).to eq(1)
    expect(links.map(&:text)).to eq(["Themes"])

    filter.filter("kanban")
    links = page.all(".sidebar-section-link-content-text")
    expect(links.count).to eq(1)
    expect(links.map(&:text)).to eq(["Components"])
  end

  it "does not show the button to customize sidebar sections, that is only supported in the main panel" do
    visit("/")
    expect(sidebar).to have_add_section_button
    visit("/admin")
    expect(sidebar).to have_no_add_section_button
  end

  it "displays limited links for moderator" do
    sign_in(moderator)
    visit("/admin")

    sidebar.toggle_all_sections

    links = page.all(".sidebar-section-link-content-text")
    expect(links.map(&:text)).to eq(
      [
        I18n.t("admin_js.admin.dashboard.title"),
        I18n.t("admin_js.admin.community.sidebar_link.users"),
        I18n.t("admin_js.admin.community.sidebar_link.groups"),
        I18n.t("admin_js.admin.account.sidebar_link.whats_new.title"),
        I18n.t("admin_js.admin.reports.sidebar_link.all"),
        I18n.t("admin_js.admin.community.sidebar_link.watched_words"),
        I18n.t("admin_js.admin.security.sidebar_link.staff_action_logs.title"),
      ],
    )
  end
end
