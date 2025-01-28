# frozen_string_literal: true

require Rails.root.join("db/migrate/20241204085540_remap_to_fa6_icon_names.rb")

RSpec.describe RemapToFa6IconNames do
  let(:migrate) { described_class.new.up }
  let(:icon_mapping) do
    {
      "fa-ambulance" => "truck-medical",
      "far-ambulance" => "far-truck-medical",
      "fab-ambulance" => "fab-truck-medical",
      "far fa-ambulance" => "far-truck-medical",
      "fab fa-ambulance" => "fab-truck-medical",
      "fas fa-ambulance" => "truck-medical",
      "fa-gear" => "gear",
      "far-gear" => "far-gear",
      "fab-gear" => "fab-gear",
      "far fa-gear" => "far-gear",
      "fab fa-gear" => "fab-gear",
      "fas fa-gear" => "gear",
      "gear" => "gear",
    }
  end

  context "when svg_icon_subset site setting has values to be remapped" do
    let!(:site_setting) do
      SiteSetting.create!(
        name: "svg_icon_subset",
        value: icon_mapping.keys.join("|"),
        data_type: SiteSettings::TypeSupervisor.types[:list],
      )
    end

    it "remaps the values correctly" do
      silence_stdout { migrate }
      expect(site_setting.reload.value.split("|")).to match_array(icon_mapping.values)
    end
  end

  context "when groups table has icons to be remapped" do
    let!(:groups) { icon_mapping.keys.map { |icon| Fabricate(:group, flair_icon: icon) } }

    it "remaps the values correctly" do
      silence_stdout { migrate }
      expect(groups.map(&:reload).map(&:flair_icon)).to match_array(icon_mapping.values)
    end
  end

  context "when post_action_types table has icons to be remapped" do
    let!(:post_action_types) do
      icon_mapping.keys.map { |icon| PostActionType.create!(name_key: "foo", icon: icon) }
    end

    it "remaps the values correctly" do
      silence_stdout { migrate }
      expect(post_action_types.map(&:reload).map(&:icon)).to match_array(icon_mapping.values)
    end
  end

  context "when badges table has icons to be remapped" do
    let!(:badges) { icon_mapping.keys.map { |icon| Fabricate(:badge, icon: icon) } }

    it "remaps the values correctly" do
      silence_stdout { migrate }
      expect(badges.map(&:reload).map(&:icon)).to match_array(icon_mapping.values)
    end
  end

  context "when sidebar_urls table has icons to be remapped" do
    let!(:sidebar_urls) { icon_mapping.keys.map { |icon| Fabricate(:sidebar_url, icon: icon) } }

    it "remaps the values correctly" do
      silence_stdout { migrate }
      expect(sidebar_urls.map(&:reload).map(&:icon)).to match_array(icon_mapping.values)
    end
  end

  context "when directory_columns table has icons to be remapped" do
    let!(:directory_columns) do
      icon_mapping.keys.map do |icon|
        DirectoryColumn.create!(enabled: true, position: 1, icon: icon)
      end
    end

    it "remaps the values correctly" do
      silence_stdout { migrate }
      expect(directory_columns.map(&:reload).map(&:icon)).to match_array(icon_mapping.values)
    end
  end

  context "when no icon names can be remapped" do
    let(:icon_names) { ["fal fa-adjust", "heart", "far-heart"] }
    let(:site_setting) do
      SiteSetting.create!(
        name: "svg_icon_subset",
        value: icon_names.join("|"),
        data_type: SiteSettings::TypeSupervisor.types[:list],
      )
    end
    let(:group) { Fabricate(:group, flair_icon: icon_names.first) }
    let(:group_2) { Fabricate(:group, flair_icon: icon_names.last) }
    let(:post_action_type) { PostActionType.create!(name_key: "foo", icon: icon_names.first) }
    let(:post_action_type_2) { PostActionType.create!(name_key: "foo", icon: icon_names.last) }
    let(:badge) { Fabricate(:badge, icon: icon_names.first) }
    let(:badge_2) { Fabricate(:badge, icon: icon_names.last) }
    let(:sidebar_url) { Fabricate(:sidebar_url, icon: icon_names.first) }
    let(:sidebar_url_2) { Fabricate(:sidebar_url, icon: icon_names.last) }
    let(:directory_column) do
      DirectoryColumn.create!(enabled: true, position: 1, icon: icon_names.first)
    end
    let(:directory_column_2) do
      DirectoryColumn.create!(enabled: true, position: 1, icon: icon_names.last)
    end

    it "does not change any icon column values" do
      expect { silence_stdout { migrate } }.not_to change {
        [
          site_setting.reload.value,
          group.reload.flair_icon,
          post_action_type.reload.icon,
          badge.reload.icon,
          sidebar_url.reload.icon,
          directory_column.reload.icon,
          group_2.reload.flair_icon,
          post_action_type_2.reload.icon,
          badge_2.reload.icon,
          sidebar_url_2.reload.icon,
          directory_column_2.reload.icon,
        ]
      }
    end
  end
end
