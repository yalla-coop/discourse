# frozen_string_literal: true

def public_root
  "#{Rails.root}/public"
end

def public_js
  "#{public_root}/javascripts"
end

def vendor_js
  "#{Rails.root}/vendor/assets/javascripts"
end

def library_src
  "#{Rails.root}/node_modules"
end

def html_for_section(group)
  icons =
    group["icons"].map do |icon|
      class_attr = icon["diversity"] ? " class=\"diversity\"" : ""
      "    {{replace-emoji \":#{icon["name"]}:\" (hash lazy=true#{class_attr} tabIndex=\"0\")}}"
    end

  <<~HTML
    <div class="section" data-section="#{group["name"]}">
      <div class="section-header">
        <span class="title">{{i18n "emoji_picker.#{group["name"]}"}}</span>
      </div>
      <div class="section-group">
        #{icons.join("\n").strip}
      </div>
    </div>
  HTML
end

def write_template(path, task_name, template)
  header = <<~JS
    // DO NOT EDIT THIS FILE!!!
    // Update it by running `rake javascript:#{task_name}`
  JS

  basename = File.basename(path)
  output_path = "#{Rails.root}/app/assets/javascripts/#{path}"

  File.write(output_path, "#{header}\n\n#{template}")
  puts "#{basename} created"
  system("yarn run prettier --write #{output_path}", exception: true)
  puts "#{basename} prettified"
end

def write_hbs_template(path, task_name, template)
  header = <<~HBS
  {{!-- DO NOT EDIT THIS FILE!!! --}}
  {{!-- Update it by running `rake javascript:#{task_name}` --}}
  HBS

  basename = File.basename(path)
  output_path = "#{Rails.root}/app/assets/javascripts/#{path}"
  File.write(output_path, "#{header}\n#{template}")
  system("yarn run prettier --write #{output_path}", exception: true)
  puts "#{basename} created"
end

def dependencies
  [
    { source: "ace-builds/src-min-noconflict/ace.js", destination: "ace.js", public: true },
    {
      source: "@json-editor/json-editor/dist/jsoneditor.js",
      package_name: "@json-editor/json-editor",
      public: true,
    },
    { source: "chart.js/dist/chart.min.js", public: true },
    { source: "chartjs-plugin-datalabels/dist/chartjs-plugin-datalabels.min.js", public: true },
    { source: "diffhtml/dist/diffhtml.min.js", public: true },
    { source: "magnific-popup/dist/jquery.magnific-popup.min.js", public: true },
    { source: "pikaday/pikaday.js", public: true },
    { source: "moment/moment.js" },
    { source: "moment/locale/.", destination: "moment-locale" },
    {
      source: "moment-timezone/builds/moment-timezone-with-data-10-year-range.js",
      destination: "moment-timezone-with-data.js",
    },
    {
      source: "@discourse/moment-timezone-names-translations/locales/.",
      destination: "moment-timezone-names-locale",
    },
    {
      source: "squoosh/codecs/mozjpeg/enc/mozjpeg_enc.js",
      destination: "squoosh",
      public: true,
      skip_versioning: true,
    },
    {
      source: "squoosh/codecs/mozjpeg/enc/mozjpeg_enc.wasm",
      destination: "squoosh",
      public: true,
      skip_versioning: true,
    },
    {
      source: "squoosh/codecs/resize/pkg/squoosh_resize.js",
      destination: "squoosh",
      public: true,
      skip_versioning: true,
    },
    {
      source: "squoosh/codecs/resize/pkg/squoosh_resize_bg.wasm",
      destination: "squoosh",
      public: true,
      skip_versioning: true,
    },
  ]
end

def node_package_name(f)
  f[:package_name] || f[:source].split("/").first
end

def public_path_name(f)
  f[:destination] || node_package_name(f)
end

def absolute_sourcemap(dest)
  File.open(dest) do |file|
    contents = file.read
    contents.gsub!(/sourceMappingURL=(.*)/, 'sourceMappingURL=/\1')
    File.open(dest, "w+") { |d| d.write(contents) }
  end
end

task "javascript:update_constants" => :environment do
  task_name = "update_constants"

  auto_groups =
    Group::AUTO_GROUPS.inject({}) do |result, (group_name, group_id)|
      result.merge(
        group_name => {
          id: group_id,
          automatic: true,
          name: group_name,
          display_name: group_name,
        },
      )
    end

  write_template("discourse/app/lib/constants.js", task_name, <<~JS)
    export const SEARCH_PRIORITIES = #{Searchable::PRIORITIES.to_json};

    export const SEARCH_PHRASE_REGEXP = '#{Search::PHRASE_MATCH_REGEXP_PATTERN}';

    export const SIDEBAR_URL = {
      max_icon_length: #{SidebarUrl::MAX_ICON_LENGTH},
      max_name_length: #{SidebarUrl::MAX_NAME_LENGTH},
      max_value_length: #{SidebarUrl::MAX_VALUE_LENGTH}
    }

    export const SIDEBAR_SECTION = {
      max_title_length: #{SidebarSection::MAX_TITLE_LENGTH},
    }

    export const AUTO_GROUPS = #{auto_groups.to_json};

    export const MAX_NOTIFICATIONS_LIMIT_PARAMS = #{NotificationsController::INDEX_LIMIT};

    export const TOPIC_VISIBILITY_REASONS = #{Topic.visibility_reasons.to_json};

    export const SYSTEM_FLAG_IDS = #{PostActionType.types.to_json}

    export const SITE_SETTING_REQUIRES_CONFIRMATION_TYPES = #{SiteSettings::TypeSupervisor::REQUIRES_CONFIRMATION_TYPES.to_json}
  JS

  pretty_notifications = Notification.types.map { |n| "  #{n[0]}: #{n[1]}," }.join("\n")

  write_template("discourse/tests/fixtures/concerns/notification-types.js", task_name, <<~JS)
    export const NOTIFICATION_TYPES = {
    #{pretty_notifications}
    };
  JS

  write_template("pretty-text/addon/emoji/data.js", task_name, <<~JS)
    export const emojis = #{Emoji.standard.map(&:name).flatten.inspect};
    export const tonableEmojis = #{Emoji.tonable_emojis.flatten.inspect};
    export const aliases = #{Emoji.aliases.inspect.gsub("=>", ":")};
    export const searchAliases = #{Emoji.search_aliases.inspect.gsub("=>", ":")};
    export const translations = #{Emoji.translations.inspect.gsub("=>", ":")};
    export const replacements = #{Emoji.unicode_replacements_json};
  JS

  write_template("pretty-text/addon/emoji/version.js", task_name, <<~JS)
    export const IMAGE_VERSION = "#{Emoji::EMOJI_VERSION}";
  JS

  groups_json = JSON.parse(File.read("lib/emoji/groups.json"))

  emoji_buttons = groups_json.map { |group| <<~HTML }
			<button type="button" data-section="#{group["name"]}" {{on "click" (fn this.onCategorySelection "#{group["name"]}")}} class="btn btn-default category-button emoji">
				 {{replace-emoji ":#{group["tabicon"]}:"}}
			</button>
    HTML

  emoji_sections = groups_json.map { |group| html_for_section(group) }

  components_dir = "discourse/app/components"
  write_hbs_template("#{components_dir}/emoji-group-buttons.hbs", task_name, emoji_buttons.join)
  write_hbs_template("#{components_dir}/emoji-group-sections.hbs", task_name, emoji_sections.join)
end

task "javascript:update" => "clean_up" do
  require "uglifier"

  system("yarn install", exception: true)

  versions = {}
  start = Time.now

  dependencies.each do |f|
    src = "#{library_src}/#{f[:source]}"

    if f[:destination]
      filename = f[:destination]
    else
      filename = f[:source].split("/").last
    end

    if f[:public_root]
      dest = "#{public_root}/#{filename}"
    elsif f[:public]
      if f[:skip_versioning]
        dest = "#{public_js}/#{filename}"
      else
        package_dir_name = public_path_name(f)
        package_version =
          JSON.parse(File.read("#{library_src}/#{node_package_name(f)}/package.json"))["version"]
        versions[filename.downcase] = "#{package_dir_name}/#{package_version}/#{filename}"

        path = "#{public_js}/#{package_dir_name}/#{package_version}"
        dest = "#{path}/#{filename}"

        FileUtils.mkdir_p(path) unless File.exist?(path)

        if src.include? "ace.js"
          versions["ace/ace.js"] = versions.delete("ace.js")

          themes = %w[theme-chrome theme-chaos]

          themes.each do |file|
            versions["ace/#{file}.js"] = "#{package_dir_name}/#{package_version}/#{file}.js"
          end

          ace_root = "#{library_src}/ace-builds/src-min-noconflict/"

          addtl_files = %w[ext-searchbox mode-html mode-scss mode-sql mode-yaml worker-html].concat(
            themes,
          )

          dest_path = dest.split("/")[0..-2].join("/")
          addtl_files.each { |file| FileUtils.cp_r("#{ace_root}#{file}.js", dest_path) }
        end
      end
    else
      dest = "#{vendor_js}/#{filename}"
    end

    STDERR.puts "New dependency added: #{dest}" unless File.exist?(dest)

    FileUtils.cp_r(src, dest)
  end

  write_template("discourse/app/lib/public-js-versions.js", "update", <<~JS)
    export const PUBLIC_JS_VERSIONS = #{versions.to_json};
  JS

  STDERR.puts "Completed copying dependencies: #{(Time.now - start).round(2)} secs"
end

task "javascript:clean_up" do
  processed = []
  dependencies.each do |f|
    next unless f[:public] && !f[:skip_versioning]

    package_dir_name = public_path_name(f)
    next if processed.include?(package_dir_name)

    versions = Dir["#{File.join(public_js, package_dir_name)}/*"].collect { |p| p.split("/").last }
    next if versions.blank?

    versions = versions.sort { |a, b| Gem::Version.new(a) <=> Gem::Version.new(b) }
    puts "Keeping #{package_dir_name} version: #{versions[-1]}"

    # Keep the most recent version
    versions[0..-2].each do |version|
      remove_path = File.join(public_js, package_dir_name, version)
      puts "Removing: #{remove_path}"
      FileUtils.remove_dir(remove_path)
    end

    processed << package_dir_name
  end
end
