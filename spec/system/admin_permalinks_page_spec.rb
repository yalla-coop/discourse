# frozen_string_literal: true

describe "Admin Permalinks Page", type: :system do
  fab!(:admin)
  fab!(:post)

  let(:admin_permalinks_page) { PageObjects::Pages::AdminPermalinks.new }
  let(:admin_permalink_form_page) { PageObjects::Pages::AdminPermalinkForm.new }

  before { sign_in(admin) }

  it "allows admin to create, edit, and destroy permalink" do
    admin_permalinks_page.visit
    expect(admin_permalinks_page).to have_no_filter

    admin_permalinks_page.click_add_permalink
    admin_permalink_form_page
      .fill_in_url("test")
      .select_permalink_type("category")
      .fill_in_category("1")
      .click_save
    expect(admin_permalinks_page).to have_permalinks("test")
    expect(admin_permalinks_page).to have_filter

    admin_permalinks_page.filter("no results")
    expect(admin_permalinks_page).to have_no_results
    expect(admin_permalinks_page).to have_filter

    admin_permalinks_page.filter("")

    admin_permalinks_page.click_edit_permalink("test")
    admin_permalink_form_page.fill_in_url("test2").click_save
    expect(admin_permalinks_page).to have_permalinks("test2")

    admin_permalinks_page.click_delete_permalink("test2")

    expect(admin_permalinks_page).to have_no_permalinks
  end

  it "allows admin to go to permalink settings page" do
    admin_permalinks_page.visit
    admin_permalinks_page.click_tab("settings")
    expect(admin_permalinks_page).to have_active_tab("settings")
  end
end
