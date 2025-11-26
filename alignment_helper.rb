# frozen_string_literal: true

# ------------------------------------------------------------------------------
# Alignment Helper
# ------------------------------------------------------------------------------
# Purpose: Streamlined helper for investigating alignment issues and errors.
# Usage:   Load via `gh("alignment")` (aliases: `gh("alignments")`, etc.) then
#          run `alignment_cheatsheet` for documentation.
# Safety:  Read-focused by default. Methods that modify state require
#          explicit confirmation via `confirm: true`.
# Notes:   Assumes the console tenant has already been selected.

ALIGNMENT_HELPER_VERSION = "0.5.0"

require "csv"

def alignment_cheatsheet
  puts "\n🚀🚀🚀 ALIGNMENT HELPER — VERSION #{ALIGNMENT_HELPER_VERSION} 🚀🚀🚀"
  puts "\n📘 Auto-loaded Variables:"
  puts "• $latest_ta → Latest team alignment (ID: #{$latest_ta&.id || 'none'})"
  puts "• $latest_ua → Latest user alignment (ID: #{$latest_ua&.id || 'none'})"

  puts "\n🔍 Query & Search:" \
    "\n• ta(org = current)              → Alignment::TeamFile::<Org> class" \
    "\n• ua(org = current)              → Alignment::UserAlignment::<Org> class" \
    "\n• team_file(org)                 → Explicit team alignment class" \
    "\n• user_alignment(org)            → Explicit user alignment class" \
    "\n• latest_team_alignment(org)     → Most recent Alignment::TeamFile record" \
    "\n• latest_user_alignment(org)     → Most recent Alignment::UserFile record" \
    "\n• pending_terminations           → Pending implicit termination records"

  puts "\n📊 Analysis & Reporting:" \
    "\n• summary(type = :user)          → Alignment success/error counts" \
    "\n• errors(type/index/message)     → Error summary or filtered alignments" \
    "\n• attributes_for_error(attrs, ref) → Raw data breakdown for an error" \
    "\n• job_titles_for_error(ref)      → Shortcut for Job Title distribution" \
    "\n• error_tally(alignment)         → Hash of error counts" \
    "\n• non_team_errors(alignment)     → Errors excluding missing team" \
    "\n• team_key_errors(alignment)     → Only team integration key errors"

  puts "\n🛠️ Utilities:" \
    "\n• raw_data(org = current)        → CSV rows for latest team file" \
    "\n• yank_alignment_data(org)       → Reminder command to pull prod data" \
    "\n• header_changes(type = :user)   → Detect header diffs across recent files" \
    "\n• analyze_headers(type = :user)  → Detailed header diff report"

  puts "\n🔧 Administrative (⚠ requires confirm: true):" \
    "\n• process_team(org, confirm: true)       → Run Alignment::TeamFile.process_latest" \
    "\n• run_latest_team_file(org, confirm: true) → Alias with status output"

  puts "\n💡 Common Usage:" \
    "\n• summary()                         # User alignment summary" \
    "\n• errors()                          # Error counts (user)" \
    "\n• errors(:team)                     # Error counts (team)" \
    "\n• errors(0)                         # Alignments for most common error" \
    "\n• attributes_for_error(['Job Title'], 0)   # Job titles for top error" \
    "\n• header_changes(:team, 3)          # Compare last three team files" \
    "\n• raw_data                          # Inspect raw CSV data" \
    "\n• gh('alignment')                   # Reload helper"
end

# Alias setup and registration
alias alignment_helper_cheatsheet alignment_cheatsheet
alias alignments_cheatsheet alignment_cheatsheet
alias alignments_helper_cheatsheet alignment_cheatsheet

ConsoleHelpers.register_helper("alignment", ALIGNMENT_HELPER_VERSION, method(:alignment_cheatsheet))

# --------------------------------- shortcuts -------------------------------- #
def ta(org = nil)
  team_file(org)
end

def ua(org = nil)
  user_alignment(org)
end

# ------------------------------------------------------------------------------
# == 🔍 QUERY & SEARCH METHODS ==
# ------------------------------------------------------------------------------

def team_file(org = nil)
  tenant = resolve_org(org)
  return nil unless tenant

  "Alignment::TeamFile::#{tenant}".constantize
rescue NameError => e
  puts "❌ Alignment::TeamFile class not found for #{tenant}: #{e.message}"
  nil
end

def user_alignment(org = nil)
  tenant = resolve_org(org)
  return nil unless tenant

  "Alignment::UserAlignment::#{tenant}".constantize
rescue NameError => e
  puts "❌ Alignment::UserAlignment class not found for #{tenant}: #{e.message}"
  nil
end

def latest_team_alignment(org = nil)
  tenant = resolve_org(org)
  return nil unless tenant

  klass = team_file(org)
  return nil unless klass

  klass.order(created_at: :desc).first
rescue => e
  puts "❌ Error loading latest team alignment for #{tenant}: #{e.message}"
  nil
end

def latest_user_alignment(org = nil)
  tenant = resolve_org(org)
  return nil unless tenant

  klass_name = "Alignment::UserFile::#{tenant}"
  klass = klass_name.safe_constantize
  unless klass
    puts "❌ #{klass_name} class not found"
    return nil
  end

  klass.order(created_at: :desc).first
rescue => e
  puts "❌ Error loading latest user alignment for #{tenant}: #{e.message}"
  nil
end

def pending_terminations
  Alignment::UserAlignment::ImplicitTermination.where(state: :pending)
rescue => e
  puts "❌ Error retrieving pending terminations: #{e.message}"
  nil
end

# ------------------------------------------------------------------------------
# == 📊 ANALYSIS & REPORTING METHODS ==
# ------------------------------------------------------------------------------

def summary(type = :user)
  case type
  when :team, :ta
    show_summary(alignment_for(:team), "Team")
  when :user, :ua
    show_summary(alignment_for(:user), "User")
  else
    puts "❌ Unknown alignment type: #{type}"
  end
end

def errors(type_or_index_or_msg = :user)
  return get_error_by_index(type_or_index_or_msg) if type_or_index_or_msg.is_a?(Integer)

  if type_or_index_or_msg.is_a?(String)
    alignment = alignment_for(:user)
    return puts "❌ No user alignment loaded" unless alignment

    results = alignment.alignments.where(error: type_or_index_or_msg)
    puts "🔍 Found #{results.count} alignments with error: '#{type_or_index_or_msg.truncate(60)}'"
    return results
  end

  case type_or_index_or_msg
  when :team, :ta
    show_errors(alignment_for(:team), "Team")
  when :user, :ua
    show_errors(alignment_for(:user), "User")
  else
    puts "❌ Unknown alignment type: #{type_or_index_or_msg}"
  end
end

def attributes_for_error(attributes, error_msg_or_index, alignment = nil)
  alignment ||= alignment_for(:user)
  return puts "❌ No user alignment loaded" unless alignment

  attributes = Array(attributes)

  error_message =
    if error_msg_or_index.is_a?(Integer)
      tally = alignment.alignments.where.not(error: nil).pluck(:error).tally.sort_by { |_, count| -count }
      return puts "❌ No errors found" if tally.empty?
      return puts "❌ Index #{error_msg_or_index} out of range (0-#{tally.length - 1})" if error_msg_or_index.negative? || error_msg_or_index >= tally.length

      tally[error_msg_or_index][0]
    else
      error_msg_or_index
    end

  rows = alignment.alignments.where(error: error_message)

  if attributes.length == 1
    attribute = attributes.first
    tally = rows.map { |record| record.raw_data&.dig(attribute) }.compact.tally
    sorted = tally.sort_by { |_, count| -count }

    puts "📊 #{attribute} (raw_data) for '#{error_message.truncate(60)}' — #{rows.count} rows"
    sorted.each { |value, count| puts "  #{count}× #{value}" }
    sorted.to_h
  else
    combos = rows.map do |record|
      attributes.map { |attr| "#{attr}: #{record.raw_data&.dig(attr) || 'nil'}" }.join(" | ")
    end.tally
    sorted = combos.sort_by { |_, count| -count }

    puts "📊 #{attributes.join(' + ')} (raw_data) for '#{error_message.truncate(60)}' — #{rows.count} rows"
    sorted.each { |combo, count| puts "  #{count}× #{combo}" }
    sorted.to_h
  end
end

def job_titles_for_error(error_msg_or_index, alignment = nil)
  attributes_for_error(["Job Title"], error_msg_or_index, alignment)
end

def error_tally(alignment = nil)
  alignment ||= alignment_for(:user)
  return nil unless alignment

  alignment.alignments.where.not(error: nil).pluck(:error).tally
rescue => e
  puts "❌ Error building error tally: #{e.message}"
  nil
end

def non_team_errors(alignment = nil)
  alignment ||= alignment_for(:user)
  return nil unless alignment

  team_error = "Couldn't find Team with [WHERE \"teams\".\"deleted_at\" IS NULL AND \"teams\".\"integration_key\" = $1]"
  alignment.alignments.where.not(error: nil).where.not(error: team_error)
rescue => e
  puts "❌ Error retrieving non-team errors: #{e.message}"
  nil
end

def team_key_errors(alignment = nil)
  alignment ||= alignment_for(:user)
  return nil unless alignment

  team_error = "Couldn't find Team with [WHERE \"teams\".\"deleted_at\" IS NULL AND \"teams\".\"integration_key\" = $1]"
  alignment.alignments.where(error: team_error)
rescue => e
  puts "❌ Error retrieving team key errors: #{e.message}"
  nil
end

# ------------------------------------------------------------------------------
# == 🛠️ UTILITY METHODS ==
# ------------------------------------------------------------------------------

def raw_data(org = nil)
  file = latest_team_alignment(org)
  return nil unless file && file.respond_to?(:raw_file)

  CSV.read(file.raw_file.download, headers: true, col_sep: "\t")
rescue => e
  puts "❌ Error reading raw data: #{e.message}"
  nil
end

def yank_alignment_data(org)
  tenant = resolve_org(org)
  return puts "❌ Unable to determine org" unless tenant

  puts "📋 To pull production alignment data for #{tenant}:"
  puts "  rake alignment:pull_prod_data[#{tenant}]"
  puts "💡 Downloads latest alignment files locally"
rescue => e
  puts "❌ Error preparing yank command: #{e.message}"
end

def header_changes(type = :user, count = 5, org: nil)
  analyze = collect_header_data(type, count, org)
  return unless analyze

  files = analyze[:files]
  info = analyze[:info]
  header_sets = analyze[:header_sets]

  return puts "❌ Need at least 2 files to compare headers" if header_sets.length < 2

  puts "🔍 Analyzing header changes across #{files.count} recent #{type} files..."
  reference = header_sets.first
  changes_detected = false

  info.each_with_index do |meta, index|
    current_headers = header_sets[index]
    label = "📁 File #{meta[:id]} (#{meta[:created]}) - #{meta[:header_count]} headers"

    if index.zero?
      puts "#{label} [LATEST]"
      puts "   Headers: #{current_headers.join(', ')}" if current_headers.any?
      puts "   ❌ Error: #{meta[:error]}" if meta[:error]
      next
    end

    added = current_headers - reference
    removed = reference - current_headers
    has_changes = added.any? || removed.any?
    changes_detected ||= has_changes

    status = has_changes ? "🚨 CHANGES DETECTED" : "✅ No changes"
    puts "\n#{label} [#{status}]"

    if has_changes
      reference_stripped = reference.map(&:strip)
      current_stripped = current_headers.map(&:strip)

      structural_added = current_stripped - reference_stripped
      structural_removed = reference_stripped - current_stripped

      whitespace_changes = reference.each_with_object([]) do |ref_header, collector|
        match = current_headers.find { |candidate| candidate.strip == ref_header.strip && candidate != ref_header }
        collector << "#{ref_header.inspect} → #{match.inspect}" if match
      end

      puts "   ➕ Added headers: #{structural_added.join(', ')}" if structural_added.any?
      puts "   ➖ Removed headers: #{structural_removed.join(', ')}" if structural_removed.any?
      if whitespace_changes.any?
        puts "   🔄 Whitespace changes: #{whitespace_changes.join(', ')}"
        puts "   ⚠️  These whitespace changes WILL break alignments in Zipline!"
      end
    end

    puts "   ❌ Error: #{meta[:error]}" if meta[:error]
  end

  puts "\n#{'=' * 60}"

  if changes_detected
    puts "🚨 HEADER CHANGES DETECTED! Likely root cause of alignment issues."
    puts "💡 Investigate data source changes, column mapping, or export formats."
  else
    puts "✅ No header changes detected across recent files."
  end

  {
    files_analyzed: files.count,
    changes_detected: changes_detected,
    file_details: info
  }
end

def analyze_headers(type = :user, count = 3, org: nil)
  analyze = collect_header_data(type, count, org)
  return unless analyze

  files = analyze[:files]
  info = analyze[:info]

  return puts "❌ Need at least 2 files to compare headers" if info.length < 2

  puts "🔍 Detailed header analysis for #{files.count} #{type} files..."
  reference = info.first
  changes_detected = false

  info.each_with_index do |meta, index|
    label = "📁 File #{meta[:id]} (#{meta[:created]}) - #{meta[:header_count]} headers"

    if index.zero?
      puts "#{label} [LATEST]"
      puts "   📋 Columns: #{meta[:headers_ordered].join(', ')}" if meta[:headers_ordered].any?
      puts "   ❌ Error: #{meta[:error]}" if meta[:error]
      next
    end

    changes = analyze_header_differences(reference, meta)
    has_changes = changes.values.any? { |list| list.any? }
    changes_detected ||= has_changes

    status = has_changes ? "🚨 CHANGES DETECTED" : "✅ No changes"
    puts "\n#{label} [#{status}]"

    display_header_changes(changes) if has_changes
    puts "   ❌ Error: #{meta[:error]}" if meta[:error]
  end

  puts "\n#{'=' * 80}"

  if changes_detected
    puts "🚨 HEADER CHANGES DETECTED!"
    puts "   • Verify upstream data sources"
    puts "   • Update column mappings if intentional"
    puts "   • Remind partners that ANY header change (including whitespace) breaks alignments"
  else
    puts "✅ No header changes detected across recent files."
  end

  {
    files_analyzed: files.count,
    changes_detected: changes_detected,
    file_details: info
  }
end

# ------------------------------------------------------------------------------
# == 🔧 ADMINISTRATIVE METHODS ==
# ------------------------------------------------------------------------------

def process_team(org = nil, confirm: false)
  return "⚠️ Requires confirm: true" unless confirm

  klass = team_file(org)
  return unless klass

  klass.process_latest
rescue => e
  puts "❌ Error processing team alignment: #{e.message}"
  nil
end

def run_latest_team_file(org = nil, confirm: false)
  return "⚠️ Add confirm: true to process alignment data" unless confirm

  klass = team_file(org)
  return unless klass

  puts "🔍 Processing latest team file via #{klass}..."
  result = klass.process_latest
  puts "✅ Processing completed"
  result
rescue => e
  puts "💥 Error processing team file: #{e.message}"
  nil
end

def get_error_by_index(index, alignment = nil)
  alignment ||= alignment_for(:user)
  return puts "❌ No user alignment loaded" unless alignment

  tally = alignment.alignments.where.not(error: nil).pluck(:error).tally.sort_by { |_, count| -count }
  return puts "❌ No errors found" if tally.empty?
  return puts "❌ Index #{index} out of range (0-#{tally.length - 1})" if index.negative? || index >= tally.length

  error_message = tally[index][0]
  rows = alignment.alignments.where(error: error_message)
  puts "🔍 Found #{rows.count} alignments with error [#{index}]: '#{error_message}'"
  rows
end

# ------------------------------------------------------------------------------
# == 🔒 PRIVATE SUPPORT METHODS ==
# ------------------------------------------------------------------------------

private

def alignment_for(type)
  case type
  when :team, :ta
    $latest_ta
  when :user, :ua
    $latest_ua
  end
end

def resolve_org(org)
  value =
    if org
      org
    elsif defined?(Organization) && Organization.respond_to?(:current) && Organization.current.respond_to?(:shortname)
      Organization.current.shortname
    elsif defined?(Apartment) && Apartment.respond_to?(:Tenant) && Apartment::Tenant.current
      Apartment::Tenant.current
    end

  return nil if value.nil?
  normalize_org(value)
end

def normalize_org(value)
  segment = value.to_s.strip
  return nil if segment.empty?

  segment.gsub(/[^a-z0-9]+/i, "_")
         .split("_")
         .reject(&:empty?)
         .map { |piece| piece[0].upcase + piece[1..].to_s.downcase }
         .join
end

def show_summary(alignment, type)
  return puts "❌ No #{type.downcase} alignment loaded" unless alignment

  total = alignment.alignments.count
  errors = alignment.alignments.where.not(error: nil).count
  success = total - errors
  percentage = total.positive? ? (success.to_f / total * 100).round(1) : 0

  puts "📊 #{type} Summary: #{total} total, #{success} success (#{percentage}%), #{errors} errors"
  { total: total, success: success, errors: errors }
end

def show_errors(alignment, type)
  return puts "❌ No #{type.downcase} alignment loaded" unless alignment

  tally = alignment.alignments.where.not(error: nil).pluck(:error).tally.sort_by { |_, count| -count }
  return puts "✅ No #{type.downcase} errors" if tally.empty?

  puts "📊 #{type} Errors:"
  tally.each_with_index { |(error, count), idx| puts "  [#{idx}] #{count}× #{error}" }
  tally
end

def analyze_header_differences(reference, current)
  ref_headers = reference[:headers_ordered]
  curr_headers = current[:headers_ordered]
  curr_by_name = current[:headers_by_name]

  changes = {
    newly_added: [],
    removed: [],
    renamed: [],
    reordered: []
  }

  ref_stripped = ref_headers.map(&:strip)
  curr_headers.each do |header|
    changes[:newly_added] << header unless ref_stripped.include?(header.strip)
  end

  curr_stripped = curr_headers.map(&:strip)
  ref_headers.each do |header|
    changes[:removed] << header unless curr_stripped.include?(header.strip)
  end

  ref_headers.each do |header|
    match = curr_headers.find { |candidate| candidate.strip == header.strip }
    changes[:renamed] << "#{header.inspect} → #{match.inspect}" if match && match != header
  end

  ref_headers.each_with_index do |header, position|
    next unless curr_by_name.key?(header)

    current_pos = curr_by_name[header]
    next if current_pos == position

    changes[:reordered] << "#{header} (was #{position + 1}, now #{current_pos + 1})"
  end

  changes
end

def display_header_changes(changes)
  if changes[:newly_added].any?
    puts "   ➕ Newly added: #{changes[:newly_added].join(', ')}"
    puts "      💡 Usually safe, but confirm mappings."
  end

  if changes[:removed].any?
    puts "   ➖ Removed: #{changes[:removed].join(', ')}"
    puts "      ⚠️ Missing columns WILL break alignments if referenced."
  end

  if changes[:renamed].any?
    puts "   🔄 Renamed/whitespace: #{changes[:renamed].join(', ')}"
    puts "      🚨 These changes WILL break Zipline alignments!"
  end

  if changes[:reordered].any?
    puts "   📍 Reordered: #{changes[:reordered].join(', ')}"
    puts "      💡 Order changes typically safe (name-based lookup)."
  end
end

def collect_header_data(type, count, org)
  klass = alignment_file_class(type, org)
  return unless klass

  files = klass.order(created_at: :desc).limit([[count, 10].min, 1].max)
  return puts "❌ No #{type} files found" if files.empty?

  header_sets_sorted = []
  headers_in_order = []
  file_info = []

  files.each do |file|
    begin
      data = file.raw_file_data
      headers =
        if data.respond_to?(:headers) && data.headers
          data.headers.to_a
        elsif data.respond_to?(:first) && data.first.respond_to?(:keys)
          Array(data.first.keys)
        elsif data.is_a?(Hash) && data.key?(:headers)
          Array(data[:headers])
        else
          []
        end

      header_sets_sorted << headers.sort
      headers_in_order << headers
      file_info << {
        id: file.id,
        created: file.created_at.strftime("%Y-%m-%d %H:%M"),
        header_count: headers.size,
        headers: headers.sort,
        headers_ordered: headers,
        headers_by_name: headers.each_with_index.to_h
      }
    rescue => e
      header_sets_sorted << []
      headers_in_order << []
      file_info << {
        id: file.id,
        created: file.created_at.strftime("%Y-%m-%d %H:%M"),
        header_count: 0,
        headers: [],
        headers_ordered: [],
        headers_by_name: {},
        error: e.message
      }
      puts "⚠️ Couldn't read headers from file #{file.id}: #{e.message}"
    end
  end

  {
    files: files,
    info: file_info,
    header_sets: header_sets_sorted,
    headers_in_order: headers_in_order
  }
end

def alignment_file_class(type, org)
  tenant = resolve_org(org)
  return nil unless tenant

  base =
    case type
    when :team, :ta
      "Alignment::TeamFile"
    when :user, :ua
      "Alignment::UserFile"
    else
      puts "❌ Unknown alignment type: #{type}"
      return nil
    end

  "#{base}::#{tenant}".constantize
rescue NameError => e
  puts "❌ #{base} class not found for #{tenant}: #{e.message}"
  nil
end

# ------------------------------------------------------------------------------
# Auto-load latest alignments and display cheatsheet
# ------------------------------------------------------------------------------

puts "🔄 Loading alignments..."
$latest_ta = latest_team_alignment
$latest_ua = latest_user_alignment
puts "✅ Loaded: TA(#{$latest_ta&.id || 'none'}), UA(#{$latest_ua&.id || 'none'})"

alignment_cheatsheet
