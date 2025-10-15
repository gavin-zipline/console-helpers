

# ------------------------------------------------------------------------------
# Simple Alignment Helper
# ------------------------------------------------------------------------------

# Purpose: Utilities for getting, setting, and pretty-printing OrganizationSetting values
# Usage: Load via `gh("simple_alignment")` then use `simple_alignment_helper_cheatsheet` for docs

SIMPLE_ALIGNMENT_HELPER_VERSION = "1.0.4"

# == Cheatsheet ==
def simple_alignment_helper_cheatsheet
  puts "\n🚀🚀🚀 SIMPLE ALIGNMENT HELPER — VERSION #{SIMPLE_ALIGNMENT_HELPER_VERSION} 🚀🚀🚀"
  puts "\n📘 Simple Alignment Helper Cheatsheet:"
  puts "\n🔍 Query & Set:"
  puts "• get_sa_setting                        → Get 'alignment_settings' value (parsed if JSON, warns if not present)"
  puts "• set_sa_setting(value)                 → Set 'alignment_settings' value (writes as JSON if Hash)"
    puts "• sa_get_file_mapping                   → Get the 'file_mapping' section from alignment_settings (or nil)"
    puts "• sa_set_file_mapping(value)            → Set the 'file_mapping' section in alignment_settings"
    puts "• sa_get_row_mappings                   → Get the 'row_mappings' array from alignment_settings (or nil)"
    puts "• sa_set_row_mappings(value)            → Set the 'row_mappings' array in alignment_settings"
  puts "\n💡 Usage Examples:"
  puts "• get_sa_setting"
  puts "• set_sa_setting({foo: 'bar'})"
  puts "• all_alignment_settings_by_org"
  puts "• file_mapping = {"
  puts "    \"parser\" => \"Xlsx\","
  puts "    \"identifier\" => \"1reLXusb-jfQ-qZ1A8XqfrWrI-uVaupQd\","
  puts "    \"source\" => \"gdrive\""
  puts "  }"
  puts "• sa_set_file_mapping(file_mapping)"
  puts "• sa_get_file_mapping"
  puts "• sa_set_file_mapping"
  puts "• sa_get_row_mappings"
  puts "• sa_set_row_mappings"

# == File Mapping Methods ==
# Returns the 'file_mapping' section from the current tenant's alignment_settings, or nil if not present.
def sa_get_file_mapping
  settings = get_sa_setting
  return nil unless settings.is_a?(Hash)
  team_file_key = "Alignment::TeamFile::Simple"
  settings.dig(team_file_key, "file_mapping")
end

# Sets the 'file_mapping' section in the current tenant's alignment_settings.
def sa_set_file_mapping(value)
  settings = get_sa_setting || {}
  team_file_key = "Alignment::TeamFile::Simple"
  settings[team_file_key] ||= {}
  settings[team_file_key]["file_mapping"] = value
  set_sa_setting(settings)
end

# == Row Mappings Methods ==
# Returns the 'row_mappings' array from the current tenant's alignment_settings, or nil if not present.
def sa_get_row_mappings
  settings = get_sa_setting
  return nil unless settings.is_a?(Hash)
  team_file_key = "Alignment::TeamFile::Simple"
  settings.dig(team_file_key, "row_mappings")
end

# Sets the 'row_mappings' array in the current tenant's alignment_settings.
def sa_set_row_mappings(value)
  settings = get_sa_setting || {}
  team_file_key = "Alignment::TeamFile::Simple"
  settings[team_file_key] ||= {}
  settings[team_file_key]["row_mappings"] = value
  set_sa_setting(settings)
end
  puts "\n📋 Quick Reference:"
  puts "• simple_alignment_helper_cheatsheet    → Show this help"
end

ConsoleHelpers.register_helper("simple_alignment", SIMPLE_ALIGNMENT_HELPER_VERSION, method(:simple_alignment_helper_cheatsheet))

# == Core Methods ==

# Gets the value for the 'alignment_settings' OrganizationSetting, parsed as JSON if possible. Warns if not present.
def get_sa_setting
  setting = OrganizationSetting.find_by(key: "alignment_settings")
  unless setting
    puts "⚠️  No 'alignment_settings' OrganizationSetting found for this tenant."
    return nil
  end
  begin
    JSON.parse(setting.value)
  rescue JSON::ParserError
    setting.value
  end
end

# Sets the value for the 'alignment_settings' OrganizationSetting (as JSON if value is a Hash)
def set_sa_setting(value)
  setting = OrganizationSetting.find_or_initialize_by(key: "alignment_settings")
  setting.value = value.is_a?(Hash) ? value.to_json : value
  setting.save!
  setting
end

# Returns a hash of Organization.shortname => alignment_settings value for all Apartment tenants (compacts nils)
def all_alignment_settings_by_org
  result = {}
  Organization.all.each do |org|
    begin
      Apartment::Tenant.switch(org.tenant_name || org.shortname) do
        setting = OrganizationSetting.find_by(key: "alignment_settings")
        result[org.shortname] = setting ? (JSON.parse(setting.value) rescue setting.value) : nil
      end
    rescue => e
      puts "⚠️  Error loading settings for org #{org.shortname}: #{e.class} - #{e.message}"
    end
  end
  result.compact
end

# Auto-display cheatsheet when helper loads
simple_alignment_helper_cheatsheet
