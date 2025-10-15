
# ------------------------------------------------------------------------------
# Simple Alignment Helper
# ------------------------------------------------------------------------------
# Purpose: Utilities for checking, getting, setting, and pretty-printing OrganizationSetting values
# Usage: Load via `gh("simple_alignment")` then use `simple_alignment_helper_cheatsheet` for docs
# Safety: Read/write, but all destructive operations require explicit confirmation

SIMPLE_ALIGNMENT_HELPER_VERSION = "1.0.0"

# == Cheatsheet ==
def simple_alignment_helper_cheatsheet
  puts "\n🚀🚀🚀 SIMPLE ALIGNMENT HELPER — VERSION #{SIMPLE_ALIGNMENT_HELPER_VERSION} 🚀🚀🚀"
  puts "\n📘 Simple Alignment Helper Cheatsheet:"
  puts "\n🔍 Query & Check:"
  puts "• sa_setting_present?(org, key)         → Check if OrganizationSetting exists for key"
  puts "• sa_get_setting(org, key)              → Get OrganizationSetting value (parsed if JSON)"
  puts "\n🛠️ Utilities:"
  puts "• sa_set_setting(org, key, value)       → Set OrganizationSetting value (writes as JSON if Hash)"
  puts "• sa_pretty_json(value)                 → Pretty-print JSON value for console readability"
  puts "\n💡 Usage Examples:"
  puts "• sa_setting_present?(Organization.first, 'my_key')"
  puts "• sa_get_setting(Organization.first, 'my_key')"
  puts "• sa_set_setting(Organization.first, 'my_key', {foo: 'bar'})"
  puts "• puts sa_pretty_json('{\"foo\":\"bar\"}')"
  puts "\n⚠️ Safety Notes:"
  puts "• All read operations are safe by default"
  puts "• Setting values will persist changes to the database"
  puts "\n📋 Quick Reference:"
  puts "• simple_alignment_helper_cheatsheet    → Show this help"
end

ConsoleHelpers.register_helper("simple_alignment", SIMPLE_ALIGNMENT_HELPER_VERSION, method(:simple_alignment_helper_cheatsheet))

# == Core Methods ==
def sa_setting_present?(organization, key)
  setting = organization.organization_settings.find_by(key: key)
  !setting.nil?
end

def sa_get_setting(organization, key)
  setting = organization.organization_settings.find_by(key: key)
  return nil unless setting
  begin
    JSON.parse(setting.value)
  rescue JSON::ParserError
    setting.value
  end
end

def sa_set_setting(organization, key, value)
  setting = organization.organization_settings.find_or_initialize_by(key: key)
  setting.value = value.is_a?(Hash) ? value.to_json : value
  setting.save!
  setting
end

def sa_pretty_json(value)
  begin
    json = value.is_a?(String) ? JSON.parse(value) : value
    JSON.pretty_generate(json)
  rescue JSON::ParserError, TypeError
    value.to_s
  end
end

# Auto-display cheatsheet when helper loads
simple_alignment_helper_cheatsheet
