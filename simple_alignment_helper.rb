
# ------------------------------------------------------------------------------
# Simple Alignment Helper
# ------------------------------------------------------------------------------

# Purpose: Utilities for getting, setting, and pretty-printing OrganizationSetting values
# Usage: Load via `gh("simple_alignment")` then use `simple_alignment_helper_cheatsheet` for docs

SIMPLE_ALIGNMENT_HELPER_VERSION = "1.0.2"

# == Cheatsheet ==
def simple_alignment_helper_cheatsheet
  puts "\n🚀🚀🚀 SIMPLE ALIGNMENT HELPER — VERSION #{SIMPLE_ALIGNMENT_HELPER_VERSION} 🚀🚀🚀"
  puts "\n📘 Simple Alignment Helper Cheatsheet:"
  puts "\n🔍 Query & Set:"
  puts "• get_sa_setting                        → Get 'alignment_settings' value (parsed if JSON, warns if not present)"
  puts "• set_sa_setting(value)                 → Set 'alignment_settings' value (writes as JSON if Hash)"
  puts "\n💡 Usage Examples:"
  puts "• get_sa_setting"
  puts "• set_sa_setting({foo: 'bar'})"
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


# Auto-display cheatsheet when helper loads
simple_alignment_helper_cheatsheet
