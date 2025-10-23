# frozen_string_literal: tr  puts "💡 Common Usage:"
  puts "  errors()                            # Show user errors (default)"
  puts "  summary()                           # User alignment summary (default)"
# ---------------------------------------------          if struc                if whitespace_changes.any?
            puts "   🚨 Whitespace changes: #{whitespace_changes.join(', ')}"
            puts "   ⚠️  These whitespace changes WILL break alignments in Zipline!" if whitespace_changes.any?
            puts "   🚨 Whitespace changes: #{whitespace_changes.join(', ')}"
            puts "   ⚠️  These whitespace changes WILL break alignments in Zipline!"
          end
        end

        puts "   ❌ Error: #{info[:error]}" if info[:error]_added.any?
            puts "   ➕ Added headers: #{structural_added.join(', ')}"
          end
          if structural_removed.any?
            puts "   ➖ Removed headers: #{structural_removed.join(', ')}"
          end
          if whitespace_changes.any?
            puts "   🚨 Whitespace changes: #{whitespace_changes.join(', ')}"
            puts "   ⚠️  These whitespace changes WILL break alignments in Zipline!"
          end
        end

        puts "   ❌ Error: #{info[:error]}" if info[:error]f whitespace_changes.any?
            puts "   🚨 Whitespace changes: #{whitespace_changes.join(', ')}"
            puts "   ⚠️  These whitespace changes WILL break alignments in Zipline!"
          end
        end

        puts "   ❌ Error: #{info[:error]}" if info[:error]----------------------------
# Alignment Helper
# ------------------------------------------------------------------------------
# Purpose: Streamlined helper for investigating alignment issues and errors.
#          Auto-loads latest alignments for immediate investigation.
# Usage: Load via `gh("alignment")` then use `alignment_cheatsheet` for docs
# Note: Assumes apartment tenant is already set in console context.

require 'csv'

ALIGNMENT_HELPER_VERSION = "0.5.0"

def alignment_cheatsheet
  puts "\n🚀🚀🚀 ALIGNMENT HELPER — VERSION #{ALIGNMENT_HELPER_VERSION} 🚀🚀🚀"
  puts "\n📘 Auto-loaded Variables:"
  puts "• $latest_ta                         → Latest team alignment (ID: #{$latest_ta&.id || 'none'})"
  puts "• $latest_ua                         → Latest user alignment (ID: #{$latest_ua&.id || 'none'})"
  puts "\n🔍 Core Investigation Methods:"
  puts "• summary(type)                      → Alignment summary (defaults to :user)"
  puts "• errors(type/index/message)         → Show errors, get by index, or get by message"
  puts "\n🛠️ Advanced Methods:"
  puts "• attributes_for_error(attrs, msg_or_index) → Breakdown raw_data attributes for specific error"
  puts "• job_titles_for_error(msg_or_index) → Job title breakdown (shortcut for above)"
  puts "• header_changes(type, count)        → 🔍 Detect column header changes (root cause detector!)"
  puts "• analyze_headers(type, count)       → 🔍 Enhanced header analysis (default: 3 files)"
  puts "• raw_data(org)                      → Latest alignment CSV data"
  puts "• process_team(org, confirm: true)   → ⚠️  Process latest team alignment"
  puts "\n💡 Common Usage:"
  puts "  errors()                            # Show user errors (default)"
  puts "  errors(0)                           # Get alignments with most common error"
  puts "  errors('Email has already been taken') # Get alignments with specific error"
  puts "  attributes_for_error(['Job Title'], 0) # Job titles for most common error"
  puts "  attributes_for_error(['Job Title', 'Org Level 4 Code'], 0) # Multi-attribute analysis"
  puts "  header_changes()                    # Check for column header changes (user files)"
  puts "  header_changes(:team, 3)            # Check team file header changes (last 3 files)"
  puts "  summary()                           # User alignment summary (default)"
  puts "  errors(:team)                       # Show team errors"
  puts "  summary(:team)                      # Team alignment summary"
  puts "  $latest_ua.alignments.limit(5)     # Inspect alignments"
  puts "  gh('alignment')                     # Reload helper if needed"
end

ConsoleHelpers.register_helper("alignment", ALIGNMENT_HELPER_VERSION, method(:alignment_cheatsheet))

# Core Investigation Methods - Streamlined and versatile



def summary(type = :user)
  case type
  when :team, :ta
    show_summary($latest_ta, "Team")
  when :user, :ua
    show_summary($latest_ua, "User")
  end
end

def errors(type_or_index_or_msg = :user)
  # If it's a number, return alignments for that error index
  if type_or_index_or_msg.is_a?(Integer)
    return get_error_by_index(type_or_index_or_msg)
  end

  # If it's a string (not a symbol), treat as error message
  if type_or_index_or_msg.is_a?(String)
    alignment = $latest_ua
    return puts "❌ No user alignment loaded" unless alignment
    alignments = alignment.alignments.where(error: type_or_index_or_msg)
    puts "🔍 Found #{alignments.count} alignments with error: '#{type_or_index_or_msg.truncate(60)}'"
    return alignments
  end

  # Otherwise show error summary by type
  case type_or_index_or_msg
  when :team, :ta
    show_errors($latest_ta, "Team")
  when :user, :ua
    show_errors($latest_ua, "User")
  end
end

# Advanced Methods
def attributes_for_error(attributes, error_msg_or_index, alignment = nil)
  alignment ||= $latest_ua
  return puts "❌ No user alignment loaded" unless alignment

  # Ensure attributes is an array
  attributes = Array(attributes)

  # If index provided, get the error message first
  if error_msg_or_index.is_a?(Integer)
    errors = alignment.alignments.where.not(error: nil).pluck(:error).tally.sort_by { |_, count| -count }
    return puts "❌ No errors found" if errors.empty?
    return puts "❌ Index #{error_msg_or_index} out of range (0-#{errors.length-1})" if error_msg_or_index >= errors.length || error_msg_or_index < 0
    error_msg = errors[error_msg_or_index][0]
  else
    error_msg = error_msg_or_index
  end

  alignments = alignment.alignments.where(error: error_msg)

  if attributes.length == 1
    # Single attribute analysis
    attribute = attributes.first
    attribute_tally = alignments.map { |a| a.raw_data&.dig(attribute) }.compact.tally
    attribute_sorted = attribute_tally.sort_by { |_, count| -count }

    puts "📊 #{attribute} (from raw_data) for error: '#{error_msg.truncate(60)}'"
    puts "Found #{alignments.count} alignments, #{attribute_tally.keys.count} distinct #{attribute.downcase} values:"
    attribute_sorted.each { |value, count| puts "  #{count}x #{value}" }
    attribute_sorted.to_h
  else
    # Multiple attributes analysis - create combinations
    combinations_tally = alignments.map do |a|
      combo = attributes.map { |attr| "#{attr}: #{a.raw_data&.dig(attr) || 'nil'}" }.join(" | ")
      combo
    end.tally
    combinations_sorted = combinations_tally.sort_by { |_, count| -count }

    puts "📊 #{attributes.join(' + ')} (from raw_data) for error: '#{error_msg.truncate(60)}'"
    puts "Found #{alignments.count} alignments, #{combinations_tally.keys.count} distinct combinations:"
    combinations_sorted.each { |combo, count| puts "  #{count}x #{combo}" }
    combinations_sorted.to_h
  end
end

# Convenience method for job titles (backward compatibility)
def job_titles_for_error(error_msg_or_index, alignment = nil)
  attributes_for_error(["Job Title"], error_msg_or_index, alignment)
end

def raw_data(org = nil)
  org ||= Apartment::Tenant.current.capitalize
  return nil unless org
  file = "Alignment::TeamFile::#{org}".constantize.order(:created_at).last
  return nil unless file&.raw_file
  CSV.read(file.raw_file.download, headers: true, col_sep: "\t")
rescue => e
  puts "❌ Error: #{e.message}"; nil
end

def process_team(org = nil, confirm: false)
  return "⚠️ Requires confirm: true" unless confirm
  org ||= Apartment::Tenant.current.capitalize
  "Alignment::TeamFile::#{org}".constantize.process_latest
rescue => e
  puts "❌ Error: #{e.message}"; nil
end

def header_changes(type = :user, count = 5)
  # Get the appropriate file class (apartment tenant is already set)
  org = Apartment::Tenant.current.capitalize
  klass_name = type == :team ? "Alignment::TeamFile::#{org}" : "Alignment::UserFile::#{org}"

  begin
    klass = klass_name.constantize
  rescue
    return puts "❌ #{type.capitalize} alignment not available"
  end

  # Get recent files
  files = klass.order(created_at: :desc).limit([count, 10].min)
  return puts "❌ No #{type} files found" if files.empty?

  puts "🔍 Analyzing header changes across #{files.count} recent #{type} files..."

  header_sets = []
  file_info = []

  files.each_with_index do |file, _index|
    begin
      # Get headers from the file data
      data = file.raw_file_data
      if data.respond_to?(:headers) && data.headers
        headers = data.headers
      elsif data.respond_to?(:first) && data.first.respond_to?(:keys)
        headers = data.first.keys
      elsif data.is_a?(Hash) && data.key?(:headers)
        headers = data[:headers]
      else
        headers = []
      end

      # Keep headers exactly as they are - whitespace matters in Zipline!
      exact_headers = headers.to_a.sort

      header_sets << exact_headers
      file_info << {
        id: file.id,
        created: file.created_at.strftime("%Y-%m-%d %H:%M"),
        header_count: headers.size,
        headers: exact_headers
      }

    rescue => e
      puts "⚠️ Couldn't read headers from file #{file.id}: #{e.message}"
      header_sets << []
      file_info << {
        id: file.id,
        created: file.created_at.strftime("%Y-%m-%d %H:%M"),
        header_count: 0,
        headers: [],
        error: e.message
      }
    end
  end

  # Analyze changes
  changes_detected = false

  if header_sets.length >= 2
    reference_headers = header_sets.first

    puts "\n📊 Header Analysis Results:"
    puts "="*60

    file_info.each_with_index do |info, index|
      current_headers = header_sets[index]

      if index == 0
        puts "📁 File #{info[:id]} (#{info[:created]}) - #{info[:header_count]} headers [LATEST]"
        puts "   Headers: #{current_headers.join(', ')}" if current_headers.any?
        puts "   ❌ Error: #{info[:error]}" if info[:error]
      else
        added = current_headers - reference_headers
        removed = reference_headers - current_headers

        has_changes = added.any? || removed.any?
        changes_detected ||= has_changes

        status = has_changes ? "🚨 CHANGES DETECTED" : "✅ No changes"
        puts "\n📁 File #{info[:id]} (#{info[:created]}) - #{info[:header_count]} headers [#{status}]"

        if has_changes
          # Separate whitespace-only changes from structural changes
          reference_stripped = reference_headers.map(&:strip)
          current_stripped = current_headers.map(&:strip)

          structural_added = current_stripped - reference_stripped
          structural_removed = reference_stripped - current_stripped

          # Find whitespace-only changes
          whitespace_changes = []
          reference_headers.each do |ref_header|
            current_match = current_headers.find { |curr| curr.strip == ref_header.strip && curr != ref_header }
            if current_match
              whitespace_changes << "#{ref_header.inspect} → #{current_match.inspect}"
            end
          end

          if structural_added.any?
            puts "   ➕ Added headers: #{structural_added.join(', ')}"
          end
          if structural_removed.any?
            puts "   ➖ Removed headers: #{structural_removed.join(', ')}"
          end
          if whitespace_changes.any?
            puts "   � Whitespace changes: #{whitespace_changes.join(', ')}"
            puts "   ⚠️  These whitespace changes WILL break alignments in Zipline!"
          end
        end        puts "   ❌ Error: #{info[:error]}" if info[:error]
      end
    end

    puts "\n" + "="*60

    if changes_detected
      puts "🚨 HEADER CHANGES DETECTED! This is likely the root cause of alignment issues."
      puts "💡 Common fixes:"
      puts "   • Check with the client about data source changes"
      puts "   • Update column mappings in the alignment file class"
      puts "   • Review recent data exports for format changes"
    else
      puts "✅ No header changes detected across recent files."
      puts "💡 Header changes are not the cause of current alignment issues."
    end
  else
    puts "❌ Need at least 2 files to compare headers"
  end

  # Return summary for programmatic use
  {
    files_analyzed: files.count,
    changes_detected: changes_detected,
    file_details: file_info
  }
rescue => e
  puts "❌ Error analyzing headers: #{e.message}"
  puts "💡 Try: header_changes(:team) or header_changes(:user, 3)"
  nil
end

def analyze_headers(type = :user, count = 3)
  # Get the appropriate file class (apartment tenant is already set)
  org = Apartment::Tenant.current.capitalize
  klass_name = type == :team ? "Alignment::TeamFile::#{org}" : "Alignment::UserFile::#{org}"

  begin
    klass = klass_name.constantize
  rescue
    return puts "❌ #{type.capitalize} alignment not available"
  end

  # Get recent files
  files = klass.order(created_at: :desc).limit([count, 10].min)
  return puts "❌ No #{type} files found" if files.empty?

  puts "🔍 Analyzing header changes across #{files.count} recent #{type} files..."

  header_data = []

  files.each_with_index do |file, _index|
    begin
      # Get headers from the file data
      data = file.raw_file_data
      if data.respond_to?(:headers) && data.headers
        headers = data.headers.to_a
      elsif data.respond_to?(:first) && data.first.respond_to?(:keys)
        headers = data.first.keys.to_a
      elsif data.is_a?(Hash) && data.key?(:headers)
        headers = data[:headers].to_a
      else
        headers = []
      end

      # Store both order-preserving and name-based data
      header_data << {
        file_id: file.id,
        created: file.created_at.strftime("%Y-%m-%d %H:%M"),
        headers_ordered: headers,  # Preserves order
        headers_by_name: headers.each_with_index.to_h,  # Maps name -> position
        header_count: headers.size
      }

    rescue => e
      puts "⚠️ Couldn't read headers from file #{file.id}: #{e.message}"
      header_data << {
        file_id: file.id,
        created: file.created_at.strftime("%Y-%m-%d %H:%M"),
        headers_ordered: [],
        headers_by_name: {},
        header_count: 0,
        error: e.message
      }
    end
  end

  return puts "❌ Need at least 2 files to compare headers" if header_data.length < 2

  puts "\n📊 Detailed Header Analysis:"
  puts "="*80

  changes_detected = false
  reference = header_data.first

  header_data.each_with_index do |current, index|
    if index == 0
      puts "📁 File #{current[:file_id]} (#{current[:created]}) - #{current[:header_count]} headers [LATEST]"
      if current[:headers_ordered].any?
        puts "   📋 Columns: #{current[:headers_ordered].join(', ')}"
      end
      puts "   ❌ Error: #{current[:error]}" if current[:error]
    else
      # Analyze the different types of changes
      changes = analyze_header_differences(reference, current)

      has_any_changes = changes.values.any? { |change_list| change_list.any? }
      changes_detected ||= has_any_changes

      status = has_any_changes ? "🚨 CHANGES DETECTED" : "✅ No changes"
      puts "\n📁 File #{current[:file_id]} (#{current[:created]}) - #{current[:header_count]} headers [#{status}]"

      if has_any_changes
        display_header_changes(changes)
      end

      puts "   ❌ Error: #{current[:error]}" if current[:error]
    end
  end

  puts "\n" + "="*80

  if changes_detected
    puts "🚨 HEADER CHANGES DETECTED! This is likely the root cause of alignment issues."
    puts "💡 Common fixes:"
    puts "   • Check with the client about data source changes"
    puts "   • Update column mappings in the alignment file class"
    puts "   • Review recent data exports for format changes"
    puts "   • ⚠️  In Zipline, ANY header change (including whitespace) breaks alignments!"
  else
    puts "✅ No header changes detected across recent files."
    puts "💡 Header changes are not the cause of current alignment issues."
  end

  # Return summary for programmatic use
  {
    files_analyzed: files.count,
    changes_detected: changes_detected,
    file_details: header_data
  }
rescue => e
  puts "❌ Error analyzing headers: #{e.message}"
  puts "💡 Try: analyze_headers(:team) or analyze_headers(:user, 3)"
  nil
end

# Helper Methods
private

def analyze_header_differences(reference, current)
  ref_headers = reference[:headers_ordered]
  curr_headers = current[:headers_ordered]
  ref_by_name = reference[:headers_by_name]
  curr_by_name = current[:headers_by_name]

  changes = {
    newly_added: [],      # Completely new columns
    removed: [],          # Columns that disappeared
    renamed: [],          # Columns that changed name/whitespace
    reordered: []         # Columns that moved position
  }

  # Find newly added columns (in current but not in reference, even when stripped)
  ref_stripped = ref_headers.map(&:strip)
  curr_headers.each do |header|
    unless ref_stripped.include?(header.strip)
      changes[:newly_added] << header
    end
  end

  # Find removed columns (in reference but not in current, even when stripped)
  curr_stripped = curr_headers.map(&:strip)
  ref_headers.each do |header|
    unless curr_stripped.include?(header.strip)
      changes[:removed] << header
    end
  end

  # Find renamed/whitespace-changed columns (same stripped name, different exact name)
  ref_headers.each do |ref_header|
    ref_stripped_name = ref_header.strip
    # Find matching column in current by stripped name
    curr_match = curr_headers.find { |h| h.strip == ref_stripped_name }

    if curr_match && curr_match != ref_header
      changes[:renamed] << "#{ref_header.inspect} → #{curr_match.inspect}"
    end
  end

  # Find reordered columns (same name, different position)
  ref_headers.each_with_index do |ref_header, ref_pos|
    curr_pos = curr_by_name[ref_header]
    if curr_pos && curr_pos != ref_pos
      changes[:reordered] << "#{ref_header} (was pos #{ref_pos + 1}, now pos #{curr_pos + 1})"
    end
  end

  changes
end

def display_header_changes(changes)
  if changes[:newly_added].any?
    puts "   ➕ Newly added: #{changes[:newly_added].join(', ')}"
    puts "      💡 New columns usually don't break existing alignments"
  end

  if changes[:removed].any?
    puts "   ➖ Removed: #{changes[:removed].join(', ')}"
    puts "      ⚠️  Missing columns WILL break alignments if they're used in logic"
  end

  if changes[:renamed].any?
    puts "   🔄 Renamed/whitespace: #{changes[:renamed].join(', ')}"
    puts "      🚨 These changes WILL break Zipline alignments!"
  end

  if changes[:reordered].any?
    puts "   📍 Reordered: #{changes[:reordered].join(', ')}"
    puts "      💡 Column order changes usually don't break alignments (name-based lookup)"
  end
end

def show_summary(alignment, type)
  return puts "❌ No #{type.downcase} alignment loaded" unless alignment
  total = alignment.alignments.count
  errors = alignment.alignments.where.not(error: nil).count
  success = total - errors
  puts "📊 #{type} Summary: #{total} total, #{success} success (#{(success.to_f/total*100).round(1)}%), #{errors} errors"
  { total: total, success: success, errors: errors }
end

def show_errors(alignment, type)
  return puts "❌ No #{type.downcase} alignment loaded" unless alignment
  errors = alignment.alignments.where.not(error: nil).pluck(:error).tally.sort_by { |_, count| -count }
  return puts "✅ No #{type.downcase} errors" if errors.empty?
  puts "📊 #{type} Errors:"
  errors.each_with_index { |(error, count), index| puts "  [#{index}] #{count}x #{error}" }
  errors
end

def get_error_by_index(index, alignment = nil)
  alignment ||= $latest_ua
  return puts "❌ No user alignment loaded" unless alignment

  errors = alignment.alignments.where.not(error: nil).pluck(:error).tally.sort_by { |_, count| -count }
  return puts "❌ No errors found" if errors.empty?
  return puts "❌ Index #{index} out of range (0-#{errors.length-1})" if index >= errors.length || index < 0

  error_message = errors[index][0]
  alignments = alignment.alignments.where(error: error_message)
  puts "🔍 Found #{alignments.count} alignments with error [#{index}]: '#{error_message}'"
  alignments
end

def get_latest(type)
  org = Apartment::Tenant.current.capitalize
  return nil unless org
  klass_name = type == :team ? "Alignment::TeamFile::#{org}" : "Alignment::UserFile::#{org}"
  klass_name.constantize.order(created_at: :desc).first
rescue
  puts "⚠️ #{type.capitalize} alignment not available"; nil
end



# Auto-load latest alignments and display cheatsheet
puts "🔄 Loading alignments..."
$latest_ta = get_latest(:team)
$latest_ua = get_latest(:user)
puts "✅ Loaded: TA(#{$latest_ta&.id}), UA(#{$latest_ua&.id})"

alignment_cheatsheet
