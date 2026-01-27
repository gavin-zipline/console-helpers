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

ALIGNMENT_HELPER_VERSION = "0.8.1"

require "csv"

def alignment_cheatsheet
  prompt_for_alignment_context

  context_display =
    if alignment_context
      "#{alignment_label(alignment_context)} (#{alignment_context})"
    else
      "not set"
    end

  latest_team = latest_alignment_file(:team, prompt: false)
  latest_user = latest_alignment_file(:user, prompt: false)

  puts "\n🚀🚀🚀 ALIGNMENT HELPER — VERSION #{ALIGNMENT_HELPER_VERSION} 🚀🚀🚀"
  puts "\n📘 Instantiated Variables:"
  puts "• alignment_context = #{context_display}"
  # show id and date created_at
  puts "• latest_alignment_file(:team) = Latest team alignment (ID: #{latest_team&.id || 'none'}, Created At: #{latest_team&.created_at || 'none'})"
  puts "• latest_alignment_file(:user) = Latest user alignment (ID: #{latest_user&.id || 'none'}, Created At: #{latest_user&.created_at || 'none'})"

  puts "\n🧭 Context Controls:" \
    "\n• set_alignment_context(:user)    → Choose default alignment focus" \
    "\n• toggle_alignment_context        → Switch between user/team contexts" \
    "\n• prompt_for_alignment_context    → Re-run the interactive prompt" \
    "\n• Context options                 → :user (default), :team"

  puts "\n🔍 Query & Search:" \
    "\n• alignment_class(type = nil)   → Alignment::(User|Team)File::<Org> run class" \
    "\n• alignment_row_class(type = nil) → Alignment::(User|Team)Alignment::<Org> row class (team row models may be absent)" \
    "\n• ta(type = :team)               → Legacy alias for alignment_class(:team)" \
    "\n• ua(type = :user)               → Legacy alias for alignment_row_class(:user)" \
    "\n• alignment_file(type = nil)     → Context-aware latest alignment file (alias of latest_alignment_file)" \
    "\n• alignments(state: nil, type: nil) → Alignment records (optionally filtered by state)" \
    "\n• alignment_records(type: nil)   → Convenience wrapper for current-context alignments" \
    "\n• team_file                     → Explicit team alignment class" \
    "\n• user_alignment                → Explicit user alignment class" \
    "\n• pending_terminations           → Pending implicit termination records" \
    "\n• alignment_row(filters = {})    → Alignment row matching raw_data filters" \
    "\n• alignment_row_by_identifier(value) → Identifier search respecting context" \
    "\n• latest_alignment_file(type = nil) → Most recent alignment run (context-aware)" \
    "\n   (Each alignment run is rooted in an Alignment::UserFile::<Org> or Alignment::TeamFile::<Org> record.)"

  puts "\n📊 Analysis & Reporting:" \
    "\n• summary                        → Context-aware alignment summary" \
    "\n• errors(target = nil, type: nil) → Error summary, index lookup, or message filter" \
    "\n• failed_alignments(type: nil)    → Alignments that failed to execute" \
    "\n• executed_alignments(type: nil)  → Successfully executed alignments" \
    "\n• unchanged_alignments(type: nil) → Alignments with no planned change" \
    "\n• normalized_data(type = nil)     → Parsed normalized payloads" \
    "\n• planned_changes(type = nil)     → Planned change payloads" \
    "\n• attributes_for_error(attrs, ref) → Raw data breakdown for an error" \
    "\n• job_titles_for_error(ref)      → Shortcut for Job Title distribution" \
    "\n• error_tally(alignment)         → Hash of error counts" \
    "\n• non_team_errors(alignment)     → Errors excluding missing team" \
    "\n• team_key_errors(alignment)     → Only team integration key errors" \
    "\n• errors_like(pattern)           → Regex search over error messages" \
    "\n• errors_containing(fragment)    → ILIKE search over error messages" \
    "\n   State filters                  → :failed, :executed, :unchanged" \
    "\n   Type overrides                 → :user, :team"

  puts "\n🛠️ Utilities:" \
    "\n• reload_latest                  → Refresh cached latest alignments" \
    "\n• raw_data                       → CSV rows for latest alignment file" \
    "\n• yank_alignment_data            → Reminder command to pull prod data" \
    "\n• header_changes(type = :user)   → Quick header diff (defaults to context)" \
    "\n• analyze_headers(type = :user)  → Verbose header diff (defaults to context)" \
    "\n• header_changes_since_last_success(type = :user) → Compare latest vs last executed (context-aware)"

  puts "\n🔧 Administrative (⚠ requires confirm: true):" \
    "\n• process_team(confirm: true)       → Run Alignment::TeamFile.process_latest" \
    "\n• run_latest_team_file(confirm: true) → Alias with status output"

  puts "\n💡 Common Usage:" \
    "\n• set_alignment_context(:user)      # Choose context once per session" \
    "\n• alignment_file                   # Latest alignment for current context" \
    "\n• failed_alignments                # Quick access to failed rows" \
    "\n• executed_alignments              # Inspect successful rows" \
    "\n• unchanged_alignments             # Review rows with no change" \
    "\n• normalized_data                  # Inspect normalized payloads" \
    "\n• planned_changes                  # Review planned changes" \
    "\n• summary                           # Summary for current context" \
    "\n• errors                            # Error counts for current context" \
    "\n• errors(0)                         # Alignments for most common error" \
    "\n• alignment_row({'Employee ID' => '123'}) # Find matching raw_data rows" \
    "\n• alignment_row_by_identifier('123') # Find row by ID/integration key" \
    "\n• latest_alignment_file           # Inspect latest alignment run" \
    "\n• header_changes                # Compare recent files for context" \
    "\n• gh('alignment')                   # Reload helper"
end

# Alias setup and registration
alias alignment_helper_cheatsheet alignment_cheatsheet
alias alignments_cheatsheet alignment_cheatsheet
alias alignments_helper_cheatsheet alignment_cheatsheet

ConsoleHelpers.register_helper("alignment", ALIGNMENT_HELPER_VERSION, method(:alignment_cheatsheet))

# ------------------------- context selection ------------------------- #
def alignment_context
  @alignment_context
end

def set_alignment_context(value = nil, quiet: false)
  context = normalize_alignment_type(value)
  unless context
    puts "❌ Unknown alignment context: #{value.inspect}. Use :user or :team." unless quiet
    return nil
  end

  previous = @alignment_context
  @alignment_context = context
  label = alignment_label(context)
  puts "✅ Alignment context set to #{label.downcase} alignments (#{context})." unless previous == context || quiet
  @alignment_context
end

# do not surfac in cheatsheet
def prompt_for_alignment_context(force: true)
  previous = @alignment_context

  if previous && !force
    return previous
  end

  unless $stdin.tty?
    if previous
      puts "ℹ️ Keeping existing alignment context #{alignment_label(previous).downcase} alignments (#{previous})."
      return previous
    end

    @alignment_context = :user
    puts "ℹ️ Defaulting alignment context to :user (non-interactive console)."
    return @alignment_context
  end

  loop do
    hint = previous ? " (press enter to keep #{previous})" : ""
    print "➡️ Set alignment context (user/team#{hint}): "
    $stdout.flush
    input = $stdin.gets

    unless input
      if previous
        puts "\n⚠️ No input detected. Keeping existing alignment context #{previous}."
        set_alignment_context(previous)
        break
      else
        puts "\n⚠️ No input detected. Defaulting alignment context to :user."
        @alignment_context = :user
        break
      end
    end

    stripped = input.strip

    if stripped.empty? && previous
      set_alignment_context(previous)
      break
    end

    context = normalize_alignment_type(stripped)
    if context
      set_alignment_context(context)
      break
    else
      puts "❌ Please enter 'user' or 'team'."
    end
  end

  @alignment_context
end

# --------------------------------- shortcuts -------------------------------- #
# NOTE: omit from cheatsheet.
def alignment_class(type = nil)
  resolved = resolve_alignment_type(type)
  return unless resolved

  base = resolved == :team ? "Alignment::TeamFile" : "Alignment::UserFile"
  locate_alignment_scoped_class(base, resolved)
end

# NOTE: omit from cheatsheet.
def alignment_row_class(type = nil)
  resolved = resolve_alignment_type(type)
  return unless resolved

  base = resolved == :team ? "Alignment::TeamAlignment" : "Alignment::UserAlignment"
  locate_alignment_scoped_class(base, resolved, allow_missing: resolved == :team)
end

def alignments(state: nil, type: nil, prompt: true)
  resolved = resolve_alignment_type(type, prompt: prompt)
  alignment = alignment_for(resolved, prompt: prompt)
  label = alignment_label(resolved)

  return puts "❌ No #{label.downcase} alignment loaded" unless alignment

  relation = alignment.alignments

  if state
    normalized_state = normalize_alignment_state(state)
    return puts "❌ Unknown alignment state: #{state.inspect}. Use :failed, :executed, or :unchanged." unless normalized_state

    relation = relation.where(state: normalized_state)
  end

  relation
rescue => e
  puts "❌ Error retrieving #{label.downcase} alignments: #{e.message}"
  nil
end

def failed_alignments(type: nil)
  alignments(state: :failed, type: type)
end

def executed_alignments(type: nil)
  alignments(state: :executed, type: type)
end

def unchanged_alignments(type: nil)
  alignments(state: :unchanged, type: type)
end

def alignment_records(type: nil)
  alignments(type: type)
end

alias raw_alignment_records alignment_records

# ------------------------------------------------------------------------------
# == 🔍 QUERY & SEARCH METHODS ==
# ------------------------------------------------------------------------------

def team_file
  alignment_class(:team)
end

def user_alignment
  alignment_row_class(:user)
end

def latest_alignment_file(type = nil, reload: false, prompt: true)
  resolved = resolve_alignment_type(type, prompt: prompt)
  return unless resolved

  label = alignment_label(resolved).downcase
  cache_iv = resolved == :team ? :@latest_ta : :@latest_ua

  klass = alignment_class(resolved)
  unless klass
    puts "❌ Alignment run class missing for #{label} scope"
    return nil
  end

  instance_variable_set(cache_iv, nil) if reload
  cached = instance_variable_get(cache_iv)

  unless cached
    cached = klass.order(created_at: :desc).first
    instance_variable_set(cache_iv, cached)
  end

  cached
rescue => e
  puts "❌ Error loading latest #{label} alignment file: #{e.message}"
  nil
end

def alignment_file(type = nil, reload: false, prompt: true)
  latest_alignment_file(type, reload: reload, prompt: prompt)
end

alias alignment alignment_file

def latest_ta
  puts "ℹ️ latest_ta delegates to latest_alignment_file(:team); prefer latest_alignment_file." unless @latest_ta_alias_notice
  @latest_ta_alias_notice = true
  latest_alignment_file(:team, prompt: false)
end

def latest_ua
  puts "ℹ️ latest_ua delegates to latest_alignment_file(:user); prefer latest_alignment_file." unless @latest_ua_alias_notice
  @latest_ua_alias_notice = true
  latest_alignment_file(:user, prompt: false)
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

def ua_summary
  puts "ℹ️ ua_summary delegates to summary(:user); consider using summary after set_alignment_context." unless @ua_summary_notice
  @ua_summary_notice = true
  summary(:user)
end

def ta_summary
  puts "ℹ️ ta_summary delegates to summary(:team); consider using summary after set_alignment_context." unless @ta_summary_notice
  @ta_summary_notice = true
  summary(:team)
end

def summary(type = nil)
  unless @alignment_summary_notice_shown
    puts "ℹ️ 'summary' now respects the alignment context. Pass :user or :team for an explicit lookup if needed."
    @alignment_summary_notice_shown = true
  end

  resolved = resolve_alignment_type(type)
  show_summary(alignment_for(resolved, prompt: false), alignment_label(resolved))
end

def errors(target = nil, type: nil)
  explicit_type = normalize_alignment_type(type)

  if explicit_type.nil? && target && !target.is_a?(Integer)
    inferred_type = normalize_alignment_type(target) if target.is_a?(Symbol) || target.is_a?(String)

    if inferred_type
      explicit_type = inferred_type
      target = nil
    end
  end

  resolved_type = resolve_alignment_type(explicit_type)
  alignment = alignment_for(resolved_type, prompt: false)
  label = alignment_label(resolved_type)

  case target
  when nil
    show_errors(alignment, label)
  when Integer
    get_error_by_index(target, alignment)
  else
    return puts "❌ No #{label.downcase} alignment loaded" unless alignment

    message = target.to_s
    results = alignment.alignments.where(error: message)
    puts "🔍 Found #{results.count} #{label.downcase} alignments with error: '#{message.truncate(60)}'"
    results
  end
end

def attributes_for_error(attributes, error_msg_or_index, alignment_or_type = nil)
  type, alignment = extract_alignment_and_type(alignment_or_type)
  label = alignment_label(type)
  return puts "❌ No #{label.downcase} alignment loaded" unless alignment

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

def job_titles_for_error(error_msg_or_index, alignment_or_type = nil)
  attributes_for_error(["Job Title"], error_msg_or_index, alignment_or_type)
end

def error_tally(alignment_or_type = nil)
  type, alignment = extract_alignment_and_type(alignment_or_type)
  return nil unless alignment

  alignment.alignments.where.not(error: nil).pluck(:error).tally
rescue => e
  puts "❌ Error building #{alignment_label(type).downcase} error tally: #{e.message}"
  nil
end

def non_team_errors(alignment_or_type = nil)
  type, alignment = extract_alignment_and_type(alignment_or_type)
  return nil unless alignment

  team_error = "Couldn't find Team with [WHERE \"teams\".\"deleted_at\" IS NULL AND \"teams\".\"integration_key\" = $1]"
  alignment.alignments.where.not(error: nil).where.not(error: team_error)
rescue => e
  puts "❌ Error retrieving non-team errors for #{alignment_label(type).downcase} alignment: #{e.message}"
  nil
end

def team_key_errors(alignment_or_type = nil)
  type, alignment = extract_alignment_and_type(alignment_or_type)
  return nil unless alignment

  team_error = "Couldn't find Team with [WHERE \"teams\".\"deleted_at\" IS NULL AND \"teams\".\"integration_key\" = $1]"
  alignment.alignments.where(error: team_error)
rescue => e
  puts "❌ Error retrieving team key errors for #{alignment_label(type).downcase} alignment: #{e.message}"
  nil
end

def errors_like(pattern, alignment_or_type = nil)
  type, alignment = extract_alignment_and_type(alignment_or_type)
  label = alignment_label(type)
  return puts "❌ No #{label.downcase} alignment loaded" unless alignment

  regex =
    if pattern.is_a?(Regexp)
      pattern
    else
      Regexp.new(Regexp.escape(pattern.to_s), Regexp::IGNORECASE)
    end

  operator = (regex.options & Regexp::IGNORECASE).positive? ? "~*" : "~"
  results = alignment.alignments.where.not(error: nil).where("error #{operator} ?", regex.source)
  puts "🔍 Found #{results.count} #{label.downcase} alignments matching #{regex.inspect}"
  results
rescue => e
  puts "❌ Error filtering #{label.downcase} errors: #{e.message}"
  nil
end

def errors_containing(fragment, alignment_or_type = nil)
  type, alignment = extract_alignment_and_type(alignment_or_type)
  label = alignment_label(type)
  return puts "❌ No #{label.downcase} alignment loaded" unless alignment

  term = fragment.to_s
  results = alignment.alignments.where.not(error: nil).where("error ILIKE ?", "%#{term}%")
  puts "🔍 Found #{results.count} #{label.downcase} alignments containing #{term.inspect}"
  results
rescue => e
  puts "❌ Error searching #{label.downcase} errors: #{e.message}"
  nil
end

# ------------------------------------------------------------------------------
# == 🛠️ UTILITY METHODS ==
# ------------------------------------------------------------------------------

def reload_latest
  puts "🔄 Refreshing latest alignments..."
  @latest_ta = latest_alignment_file(:team, reload: true, prompt: false)
  @latest_ua = latest_alignment_file(:user, reload: true, prompt: false)
  puts "✅ Loaded: TA(#{@latest_ta&.id || 'none'}), UA(#{@latest_ua&.id || 'none'})"
  { team: @latest_ta, user: @latest_ua }
end

def raw_data(type = nil, quiet: false)
  alignment_dataset(:raw, type: type, quiet: quiet)
end

def normalized_data(type = nil, quiet: false)
  alignment_dataset(:normalized, type: type, quiet: quiet)
end

def planned_changes(type = nil, quiet: false)
  alignment_dataset(:planned_changes, type: type, quiet: quiet)
end

def alignment_dataset(dataset, type: nil, quiet: false)
  resolved = resolve_alignment_type(type)
  label = alignment_label(resolved).downcase

  file = latest_alignment_file(resolved, prompt: false)
  unless file
    puts "❌ No latest #{label} alignment available" unless quiet
    return nil
  end

  case dataset
  when :raw
    read_raw_alignment(file, label, quiet: quiet)
  when :normalized
    read_serialized_dataset(file, :normalized_data, label, quiet: quiet)
  when :planned_changes
    read_serialized_dataset(file, :planned_changes, label, quiet: quiet)
  else
    puts "❌ Unknown alignment dataset: #{dataset.inspect}" unless quiet
    nil
  end
end

def yank_alignment_data
  tenant = resolve_org
  return puts "❌ Unable to determine org" unless tenant

  puts "📋 To pull production alignment data for #{tenant}:"
  puts "  rake alignment:pull_prod_data[#{tenant}]"
  puts "💡 Downloads latest alignment files locally"
rescue => e
  puts "❌ Error preparing yank command: #{e.message}"
end

def alignment_row(filters = {}, alignment_or_type = nil)
  filters = filters.to_h
  return puts "❌ Provide at least one filter" if filters.empty?

  type, alignment = extract_alignment_and_type(alignment_or_type)
  label = alignment_label(type)
  label_downcase = label.downcase
  return puts "❌ No #{label_downcase} alignment loaded" unless alignment

  scope = filters.reduce(alignment.alignments) do |relation, (key, value)|
    relation.where("raw_data ->> ? = ?", key.to_s, value.to_s)
  end

  record = scope.first
  if record
    puts "✅ Found #{label_downcase} alignment #{record.id} matching #{filters.inspect}"
    record
  else
    puts "❌ No #{label_downcase} alignment row found for #{filters.inspect}"
    nil
  end
rescue => e
  puts "❌ Error searching #{label_downcase} alignment rows: #{e.message}"
  nil
end

def alignment_row_by_identifier(identifier, alignment_or_type = nil)
  type, alignment = extract_alignment_and_type(alignment_or_type)
  label = alignment_label(type)
  label_downcase = label.downcase
  return puts "❌ No #{label_downcase} alignment loaded" unless alignment

  keys = identifier_columns_for(type)
  if keys.empty?
    puts "❌ Identifier lookup not configured for #{label_downcase} alignments"
    return nil
  end

  keys.each do |key|
    record = alignment.alignments.where("raw_data ->> ? = ?", key, identifier.to_s).first
    next unless record

    puts "✅ Found #{label_downcase} alignment #{record.id} via #{key}"
    return record
  end

  puts "❌ No #{label_downcase} alignment row found for #{identifier.inspect} using #{keys.join(', ')}"
  nil
rescue => e
  puts "❌ Error finding #{label_downcase} alignment row: #{e.message}"
  nil
end

alias ua_row alignment_row
alias ua_by_employee alignment_row_by_identifier

def inspect_headers(type = nil, count: 5, verbose: false)
  resolved_type = resolve_alignment_type(type)
  analyze = collect_header_data(resolved_type, count)
  return unless analyze

  files = analyze[:files]
  info = analyze[:info]
  header_sets = analyze[:header_sets]

  return puts "❌ Need at least 2 files to compare headers" if info.length < 2

  if verbose
    puts "🔍 Detailed header analysis for #{files.count} #{resolved_type} files..."
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
  else
    puts "🔍 Analyzing header changes across #{files.count} recent #{resolved_type} files..."
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
end

def header_changes(type = nil, count = 5)
  inspect_headers(type, count: count, verbose: false)
end

def analyze_headers(type = nil, count = 3)
  inspect_headers(type, count: count, verbose: true)
end

# ------------------------------------------------------------------------------
# == 🔧 ADMINISTRATIVE METHODS ==
# ------------------------------------------------------------------------------

def process_team(confirm: false)
  return "⚠️ Requires confirm: true" unless confirm

  klass = team_file
  return unless klass

  klass.process_latest
rescue => e
  puts "❌ Error processing team alignment: #{e.message}"
  nil
end

def run_latest_team_file(confirm: false)
  return "⚠️ Add confirm: true to process alignment data" unless confirm

  klass = team_file
  return unless klass

  puts "🔍 Processing latest team file via #{klass}..."
  result = klass.process_latest
  puts "✅ Processing completed"
  result
rescue => e
  puts "💥 Error processing team file: #{e.message}"
  nil
end

def get_error_by_index(index, alignment_or_type = nil)
  type, alignment = extract_alignment_and_type(alignment_or_type)
  label = alignment_label(type)
  return puts "❌ No #{label.downcase} alignment loaded" unless alignment

  tally = alignment.alignments.where.not(error: nil).pluck(:error).tally.sort_by { |_, count| -count }
  return puts "❌ No errors found" if tally.empty?
  return puts "❌ Index #{index} out of range (0-#{tally.length - 1})" if index.negative? || index >= tally.length

  error_message = tally[index][0]
  rows = alignment.alignments.where(error: error_message)
  puts "🔍 Found #{rows.count} #{label.downcase} alignments with error [#{index}]: '#{error_message}'"
  rows
end

# ------------------------------------------------------------------------------
# == 🔒 PRIVATE SUPPORT METHODS ==
# ------------------------------------------------------------------------------

private

def alignment_for(type = nil, prompt: true)
  latest_alignment_file(type, prompt: prompt)
end

def resolve_alignment_type(value = nil, prompt: true)
  normalized = normalize_alignment_type(value)
  return normalized if normalized

  return @alignment_context if @alignment_context

  prompt ? prompt_for_alignment_context(force: false) : nil
end

def alignment_label(type)
  case type
  when :team
    "Team"
  when :user
    "User"
  else
    "Alignment"
  end
end

def alignment_type_for(alignment)
  return nil unless alignment

  klass = alignment.class.name
  return :team if klass&.include?("Alignment::TeamFile")
  return :user if klass&.include?("Alignment::UserFile")

  @alignment_context
end

def extract_alignment_and_type(alignment_or_type = nil, prompt: true)
  if alignment_or_type.is_a?(Symbol) || alignment_or_type.is_a?(String)
    type = resolve_alignment_type(alignment_or_type, prompt: prompt)
    return [type, alignment_for(type, prompt: false)]
  elsif alignment_or_type
    type = alignment_type_for(alignment_or_type) || resolve_alignment_type(nil, prompt: prompt)
    return [type, alignment_or_type]
  else
    type = resolve_alignment_type(nil, prompt: prompt)
    return [type, alignment_for(type, prompt: false)]
  end
end

def normalize_alignment_type(value)
  return nil if value.nil?

  token =
    case value
    when Symbol
      value.to_s
    when String
      value
    else
      return nil
    end

  case token.strip.downcase
  when "user", "users", "ua", "u"
    :user
  when "team", "teams", "ta", "t"
    :team
  else
    nil
  end
end

def normalize_alignment_state(value)
  return nil if value.nil?

  token =
    case value
    when Symbol
      value.to_s
    when String
      value
    else
      return nil
    end

  case token.strip.downcase
  when "failed"
    :failed
  when "executed"
    :executed
  when "unchanged"
    :unchanged
  else
    nil
  end
end

def identifier_columns_for(type)
  case type
  when :team
    [
      "Team Integration Key",
      "Team ID",
      "Team Number",
      "Store Number",
      "Location Number",
      "Team External ID"
    ]
  when :user
    [
      "Employee Integration Key",
      "Employee ID",
      "Employee Number",
      "Employee External ID"
    ]
  else
    []
  end
end

def locate_alignment_scoped_class(base, _resolved = nil, allow_missing: false)
  tenants = tenant_candidates
  return nil if tenants.empty?

  tenants.each do |tenant|
    begin
      return resolve_alignment_constant(base, tenant)
    rescue NameError
      next
    end
  end

  message =
    if allow_missing
      "ℹ️ #{base} class not defined for #{tenants.join(', ')}"
    else
      "❌ #{base} class not found for #{tenants.join(', ')}"
    end

  if allow_missing
    @missing_alignment_class_messages ||= {}
    key = [base, tenants.sort]
    puts message unless @missing_alignment_class_messages[key]
    @missing_alignment_class_messages[key] = true
  else
    puts message
  end
  nil
end

def resolve_org
  tenant_candidates.first
end

def resolve_alignment_constant(base, tenant)
  "#{base}::#{tenant}".constantize
rescue NameError
  base_module = base.constantize
  match = base_module.descendants.find { |klass| klass.name.demodulize.casecmp?(tenant) }
  raise NameError, "#{base} constant not found for #{tenant}" unless match

  match
end

def tenant_candidates
  candidates = []

  if defined?(Organization) && Organization.respond_to?(:current)
    org = Organization.current
    if org
      candidates << normalize_org(org.as_module, preserve_case: true) if org.respond_to?(:as_module)
      candidates << normalize_org(org.shortname) if org.respond_to?(:shortname)
    end
  end

  if defined?(Apartment) && Apartment.respond_to?(:Tenant) && Apartment::Tenant.current
    candidates << normalize_org(Apartment::Tenant.current)
  end

  candidates.compact.uniq
end

def normalize_org(value, preserve_case: false)
  segment = value.to_s.strip
  return nil if segment.empty?

  sanitized = segment.gsub(/[^a-z0-9]+/i, "_")

  if preserve_case || segment.match?(/[A-Z]/)
    sanitized.delete("_")
  else
    sanitized.split("_")
             .reject(&:empty?)
             .map { |piece| piece[0].upcase + piece[1..].to_s.downcase }
             .join
  end
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

def header_info_for(file)
  info = {
    id: file.id,
    created: file.created_at.strftime("%Y-%m-%d %H:%M"),
    header_count: 0,
    headers: [],
    headers_ordered: [],
    headers_by_name: {},
    error: nil
  }

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

  info[:header_count] = headers.size
  info[:headers] = headers.sort
  info[:headers_ordered] = headers
  info[:headers_by_name] = headers.each_with_index.to_h
  info
rescue => e
  info[:error] = e.message
  info
end

def collect_header_data(type, count)
  klass = alignment_class(type)
  return unless klass

  files = klass.order(created_at: :desc).limit([[count, 10].min, 1].max)
  label = alignment_label(type)
  return puts "❌ No #{label.downcase} files found" if files.empty?

  header_sets_sorted = []
  headers_in_order = []
  file_info = []

  files.each do |file|
    info = header_info_for(file)
    header_sets_sorted << info[:headers]
    headers_in_order << info[:headers_ordered]
    file_info << info
    puts "⚠️ Couldn't read headers from file #{file.id}: #{info[:error]}" if info[:error]
  end

  {
    files: files,
    info: file_info,
    header_sets: header_sets_sorted,
    headers_in_order: headers_in_order
  }
end

def latest_alignment_for(type = nil)
  puts "ℹ️ latest_alignment_for delegates to latest_alignment_file; prefer latest_alignment_file." unless @latest_alignment_for_notice
  @latest_alignment_for_notice = true
  latest_alignment_file(type)
end

def last_successful_alignment_for(type = nil, before: nil)
  resolved = resolve_alignment_type(type)
  klass = alignment_class(resolved)
  return unless klass

  scope = klass.where(state: :executed)
  scope = scope.where("created_at < ?", before) if before
  scope.order(created_at: :desc).first
rescue => e
  puts "❌ Error locating last successful #{alignment_label(resolved).downcase} alignment: #{e.message}"
  nil
end

def header_changes_since_last_success(type = nil, verbose: false)
  resolved = resolve_alignment_type(type)
  label = alignment_label(resolved).downcase

  latest = latest_alignment_file(resolved, prompt: false)
  return puts "❌ No latest #{label} alignment found" unless latest

  previous = last_successful_alignment_for(resolved, before: latest.created_at)
  return puts "❌ No successful #{label} alignment found prior to latest" unless previous

  latest_info = header_info_for(latest)
  prev_info = header_info_for(previous)

  if latest_info[:error]
    puts "❌ Unable to read headers for latest file #{latest.id}: #{latest_info[:error]}"
    return
  end

  if prev_info[:error]
    puts "❌ Unable to read headers for prior successful file #{previous.id}: #{prev_info[:error]}"
    return
  end

  puts "🔍 Comparing latest #{label} file ##{latest.id} (#{latest.state}, #{latest_info[:header_count]} headers)"
  puts "    against last executed #{label} file ##{previous.id} (#{previous.state}, #{prev_info[:header_count]} headers)"

  changes = analyze_header_differences(prev_info, latest_info)
  has_changes = changes.values.any? { |list| list.any? }

  if has_changes
    display_header_changes(changes)
    if verbose
      puts "   📋 Latest headers: #{latest_info[:headers_ordered].join(', ')}"
      puts "   📋 Previous headers: #{prev_info[:headers_ordered].join(', ')}"
    end
    puts "🚨 Header differences detected vs last successful #{label} alignment."
  else
    puts "✅ No header differences detected vs last successful #{label} alignment."
    puts "   📋 Headers: #{latest_info[:headers_ordered].join(', ')}" if verbose
  end

  {
    latest: latest,
    previous: previous,
    changes: changes,
    changes_detected: has_changes
  }
end

def alignment_file_class(type = nil)
  puts "ℹ️ alignment_file_class delegates to alignment_class; prefer alignment_class." unless @alignment_file_class_notice
  @alignment_file_class_notice = true
  alignment_class(type)
end

def read_raw_alignment(file, label, quiet: false)
  unless file.respond_to?(:raw_file)
    puts "❌ Latest #{label} alignment does not expose raw_file" unless quiet
    return nil
  end

  attachment = file.raw_file
  unless attachment
    puts "❌ Latest #{label} alignment does not have a raw_file attachment" unless quiet
    return nil
  end

  if attachment.respond_to?(:open)
    attachment.open do |tempfile|
      return CSV.read(tempfile.path, headers: true, col_sep: "\t")
    end
  elsif attachment.respond_to?(:download)
    data = attachment.download
    return CSV.parse(data.to_s, headers: true, col_sep: "\t")
  elsif attachment.respond_to?(:path)
    return CSV.read(attachment.path, headers: true, col_sep: "\t")
  end

  puts "❌ Latest #{label} alignment raw_file is not readable" unless quiet
  nil
rescue => e
  puts "❌ Error reading #{label} raw data: #{e.message}" unless quiet
  nil
end

def read_serialized_dataset(file, attribute, label, quiet: false)
  unless file.respond_to?(attribute)
    puts "❌ Latest #{label} alignment does not expose #{attribute}" unless quiet
    return nil
  end

  data = file.public_send(attribute)

  if data.respond_to?(:deep_dup)
    data.deep_dup
  elsif data.is_a?(Hash) || data.is_a?(Array)
    Marshal.load(Marshal.dump(data))
  else
    data
  end
rescue => e
  puts "❌ Error reading #{label} #{attribute}: #{e.message}" unless quiet
  nil
end

def alignment_helper_smoke_test(verbose: false)
  contexts = [:user, :team]
  previous_context = alignment_context

  results = contexts.map do |ctx|
    set_alignment_context(ctx, quiet: true)
    file = alignment_file(ctx, prompt: false)
    label = alignment_label(ctx).downcase

    info = {
      context: ctx,
      file_id: file&.id,
      state_counts: {},
      datasets: {}
    }

    if file
      begin
        info[:state_counts] = file.alignments.group(:state).count
      rescue => e
        info[:state_counts_error] = verbose ? e : e.message
      end

      begin
        table = read_raw_alignment(file, label, quiet: true)
        info[:datasets][:raw] =
          if table
            { rows: table.count, headers: table.headers&.count }
          else
            :missing
          end
      rescue => e
        info[:datasets][:raw] = verbose ? e : e.message
      end

      begin
        normalized = read_serialized_dataset(file, :normalized_data, label, quiet: true)
        info[:datasets][:normalized] = normalized ? (verbose ? normalized : :ok) : :missing
      rescue => e
        info[:datasets][:normalized] = verbose ? e : e.message
      end

      begin
        planned = read_serialized_dataset(file, :planned_changes, label, quiet: true)
        info[:datasets][:planned_changes] = planned ? (verbose ? planned : :ok) : :missing
      rescue => e
        info[:datasets][:planned_changes] = verbose ? e : e.message
      end
    else
      info[:datasets] = { raw: :no_file, normalized: :no_file, planned_changes: :no_file }
    end

    info
  end

  summary_line = results.map do |result|
    context = result[:context]
    file_id = result[:file_id] || "none"
    counts = result[:state_counts]

    state_summary =
      if counts && counts.any?
        counts.map { |state, count| "#{state}=#{count}" }.join(", ")
      else
        "states=none"
      end

    "#{context}:#{file_id} (#{state_summary})"
  end.join(" | ")

  puts "alignment_helper_smoke_test ✅ #{summary_line}"

  verbose ? results : results
ensure
  if previous_context
    set_alignment_context(previous_context, quiet: true)
  else
    @alignment_context = nil
  end
end

# ------------------------------------------------------------------------------
# Auto-load latest alignments and display cheatsheet
# ------------------------------------------------------------------------------

puts "🔄 Loading alignments..."
reload_latest
alignment_cheatsheet
