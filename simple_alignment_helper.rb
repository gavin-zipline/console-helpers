# ------------------------------------------------------------------------------
# Simple Alignment Helper
# ------------------------------------------------------------------------------
# Purpose: Utilities for getting, setting, and pretty-printing OrganizationSetting values
# Usage: Load via `gh("simple_alignment")` then use `simple_alignment_helper_cheatsheet` for docs

SIMPLE_ALIGNMENT_HELPER_VERSION = "1.1.0"

def simple_alignment_helper_cheatsheet
  puts "• get_file_mapping                      → Get the 'file_mapping' section from alignment_settings (or nil)"
  puts "• set_file_mapping(value)               → Set the 'file_mapping' section in alignment_settings"
  puts "• get_row_mappings                      → Get the 'row_mappings' array from alignment_settings (or nil)"
  puts "• set_row_mappings(value)               → Set the 'row_mappings' array in alignment_settings"
  puts "\n🔄 Alignment Automation:"
  puts "• alignments_enabled?                    → Is auto alignment enabled? (OrganizationSetting.auto_alignments_enabled?)"
  puts "• enabled_alignments                     → Array of enabled automated alignments (OrganizationSetting.automated_alignments.to_a)"
  puts "• enable_ta                              → Enable team alignment automation for this org"
  puts "• disable_ta                             → Disable team alignment automation for this org"
  puts "• enable_ua                              → Enable user alignment automation for this org"
  puts "• disable_ua                             → Disable user alignment automation for this org"
  puts "• run_ta                                 → Enqueue the team alignment job (Alignment::ProcessLatestAlignmentsJob.perform_async, team only)"
  puts "• run_ua                                 → Enqueue the user alignment job (Alignment::ProcessLatestAlignmentsJob.perform_async, user only)"
  puts "\n� Usage Examples:"
  puts "get_sa_setting"
  puts "get_file_mapping"
  puts "get_row_mappings"
  puts "set_sa_setting(setting_hash)"
  puts "examples = all_alignment_settings_by_org"
  puts "run_ta"
  puts "run_ua"
  puts "\n=== SET FILE MAPPING EXAMPLE ==="
  puts "file_mapping = {"
  puts "  \"parser\" => \"Xlsx\","
  puts "  \"identifier\" => \"1reLXusb-jfQ-qZ1A8XqfrWrI-uVaupQd\","
  puts "  \"source\" => \"gdrive\""
  puts "}"
  puts "set_file_mapping(file_mapping)"
  puts "\n=== SET ROW MAPPINGS EXAMPLE ==="
  puts "set_row_mappings(row_mappings)"
  puts "\n📋 Quick Reference:"
  puts "• simple_alignment_helper_cheatsheet    → Show this help"
  puts "alignments_enabled?"
  puts "enabled_alignments"
  puts "enable_ta"
  puts "disable_ta"
  puts "enable_ua"
  puts "disable_ua"
end

ConsoleHelpers.register_helper("simple_alignment", SIMPLE_ALIGNMENT_HELPER_VERSION, method(:simple_alignment_helper_cheatsheet))

# == Test File Mapping ==
# Attempts to access the file specified in the current file mapping and prints the result.
def test_file_mapping
  file_mapping = get_file_mapping
  unless file_mapping
    puts "⚠️  No file mapping found."
    return false
  end
  source = file_mapping["source"]
  identifier = file_mapping["identifier"]
  parser = file_mapping["parser"]
  puts "Testing file mapping:"
  puts "  Source:      #{source}"
  puts "  Identifier:  #{identifier}"
  puts "  Parser:      #{parser}"
  begin
    team_file = Alignment::TeamFile::Simple.new
    # Print raw file content
    raw = nil
    team_file.raw_file.open { |f| raw = f.read }
    puts "--- RAW FILE CONTENT (first 500 chars) ---"
    puts raw ? raw[0, 500] : '(no content)'
    puts "--- END RAW FILE CONTENT ---"
    # Now parse
    data = team_file.raw_file_data
    puts "Parsed data class: #{data.class}, size: #{data.respond_to?(:size) ? data.size : 'n/a'}"
    if data.nil? || (data.respond_to?(:empty?) && data.empty?)
      puts "❌ File mapping test failed: No data returned from parser."
      return false
    end
    puts "✅ File mapping test succeeded! Parsed data sample:"
    if data.respond_to?(:first)
      puts data.first.inspect
      if data.respond_to?(:headers)
        puts "Headers: #{data.headers.inspect}"
      end
    else
      puts data.inspect
    end
    true
  rescue => e
    puts "❌ File mapping test failed: #{e.class} - #{e.message}"
    puts e.backtrace.first(5)
    false
  end
end

# == Alignment Run Methods ==
# Run the team alignment directly using process_latest on the enabled alignment class
def run_ta
  klass_name = enabled_alignments.find { |k| k =~ /TeamFile::Simple/ }
  unless klass_name
    puts "No enabled team alignment class found."
    return nil
  end
  klass = klass_name.constantize
  puts "Running team alignment: #{klass_name}.process_latest"
  result = klass.process_latest
  puts "Result: #{result.inspect}"
  result
end

# Run the user alignment directly using process_latest on the enabled alignment class
def run_ua
  klass_name = enabled_alignments.find { |k| k =~ /UserFile::Simple/ }
  unless klass_name
    puts "No enabled user alignment class found."
    return nil
  end
  klass = klass_name.constantize
  puts "Running user alignment: #{klass_name}.process_latest"
  result = klass.process_latest
  puts "Result: #{result.inspect}"
  result
end

# == Core Get/Set Methods ==
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

def set_sa_setting(value)
  setting = OrganizationSetting.find_or_initialize_by(key: "alignment_settings")
  setting.value = value.is_a?(Hash) ? value.to_json : value
  setting.save!
  setting
end

# == File Mapping Methods ==
def get_file_mapping
  settings = get_sa_setting
  return nil unless settings.is_a?(Hash)
  team_file_key = "Alignment::TeamFile::Simple"
  settings.dig(team_file_key, "file_mapping")
end

def set_file_mapping(value)
  settings = get_sa_setting || {}
  team_file_key = "Alignment::TeamFile::Simple"
  settings[team_file_key] ||= {}
  settings[team_file_key]["file_mapping"] = value
  set_sa_setting(settings)
end

# == Row Mappings Methods ==
def get_row_mappings
  settings = get_sa_setting
  return nil unless settings.is_a?(Hash)
  team_file_key = "Alignment::TeamFile::Simple"
  settings.dig(team_file_key, "row_mappings")
end

def set_row_mappings(value)
  settings = get_sa_setting || {}
  team_file_key = "Alignment::TeamFile::Simple"
  settings[team_file_key] ||= {}
  settings[team_file_key]["row_mappings"] = value
  set_sa_setting(settings)
end

# == Alignment Automation Methods ==
def alignments_enabled?
  OrganizationSetting.auto_alignments_enabled?
end

# Returns array of enabled automated alignments
def enabled_alignments
  OrganizationSetting.automated_alignments.to_a.map { |klass| klass.name }
end

# Enable/disable team alignment automation for this org
def enable_ta
  klass = "Alignment::TeamFile::Simple"
  current = enabled_alignments
  unless current.include?(klass)
    OrganizationSetting.automated_alignments = current + [klass]
    puts "Team alignment automation enabled."
  else
    puts "Team alignment automation already enabled."
  end
end

def disable_ta
  klass = "Alignment::TeamFile::Simple"
  current = enabled_alignments
  if current.include?(klass)
    OrganizationSetting.automated_alignments = current - [klass]
    puts "Team alignment automation disabled."
  else
    puts "Team alignment automation already disabled."
  end
end

# Enable/disable user alignment automation for this org
def enable_ua
  klass = "Alignment::UserFile::Simple"
  current = enabled_alignments
  unless current.include?(klass)
    OrganizationSetting.automated_alignments = current + [klass]
    puts "User alignment automation enabled."
  else
    puts "User alignment automation already enabled."
  end
end

def disable_ua
  klass = "Alignment::UserFile::Simple"
  current = enabled_alignments
  if current.include?(klass)
    OrganizationSetting.automated_alignments = current - [klass]
    puts "User alignment automation disabled."
  else
    puts "User alignment automation already disabled."
  end
end

# == All Orgs Bulk Fetch ==
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
# == Auto-display cheatsheet ==
simple_alignment_helper_cheatsheet
