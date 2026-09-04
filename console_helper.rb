CONSOLE_HELPER_VERSION = "0.4.0"
def console_cheatsheet
  puts "\n🧪 Console Helper Cheatsheet"
  puts "• list_recent_history(count = 25) or lrh(count = 25)"
  puts "  → Prints the last 'count' commands from IRB history with their index for reference."
  puts ""
  puts "• run_history(index)"
  puts "  → Asks for confirmation, then executes the command at the given history index."
  puts ""
  puts "• ass_counts"
  puts "  → Returns a hash where each key is an association name, and the value is either the count (if zero) or an array: [count, copy-paste snippet] for nonzero counts."
  puts "    Example: {:subscribers=>[301, 'distribution_list_subscribers = distribution_list.subscribers'], :subscriptions=>0, ...}"
  puts ""
  puts "• nested_classes or nc"
  puts "  → Lists subclasses nested under a module or class."
  puts ""
  puts "• variablize_url(url) → Generate ID + find line for one URL"
  puts "• variablize_urls([url1, url2, ...]) → Same for multiple"
  puts "• variablize_urls_from_clipboard → Extract URLs from clipboard and variablize"
  puts ""
  puts "• service_account_impersonator(user) → Copy user's permissions, team_memberships, and security_role to service account for testing"
  puts "• service_account_impersonator(:reset) → Restore service account's original state"
  puts ""
  puts "• data_age (or da) / data_age(fast: true)"
  puts "  → Answers TWO questions separately, leading with a verdict: LIVE TENANT / STUB / EMPTY / UNCERTAIN."
  puts "    IDENTITY  (row counts)      → is this the real tenant, or a stub / frozen clone / empty schema?"
  puts "    FRESHNESS (max timestamps)  → how current is the data?"
  puts "    Samples User, Team, Communication, Task, EventStream::Event, Audited::Audit and shows where"
  puts "    they disagree. Counts are capped at #{DATA_AGE_COUNT_CAP}; timestamps are best-effort under a #{DATA_AGE_TIME_BUDGET.to_i}s budget."
  puts "    fast: true skips timestamps (identity only). Returns the verdict symbol."
  puts "    NOT a clearance check — still count the domain model you care about yourself."
  puts ""
  puts "• keep_alive → Keeps session alive; auto-exits after 2 hours of inactivity (runs on load)"
end

def cheatsheet
  console_cheatsheet
end

def enable_return_printing; end
def disable_return_printing; end

# == LOADED HELPERS REGISTRY ==
# Tracks loaded helpers, their versions, and cheatsheet procs
module ConsoleHelpers
  @@loaded_helpers = {}

  def self.register_helper(helper_name, version, cheatsheet_proc)
    @@loaded_helpers[helper_name] = {
      version: version,
      cheatsheet: cheatsheet_proc
    }
  end

  def self.helpers
    @@loaded_helpers.map { |name, info| "#{name} (v#{info[:version]})" }
  end
  def self.cheatsheets
    @@loaded_helpers.map do |name, info|
      "--- #{name} (v#{info[:version]}) ---\n" + info[:cheatsheet].call.to_s
    end.join("\n\n")
  end
end
ConsoleHelpers.register_helper("console", CONSOLE_HELPER_VERSION, method(:console_cheatsheet))
## (removed invalid placeholder)

# Convenience global methods for helpers registry
def helpers
  ConsoleHelpers.helpers
end

def cheatsheets
  ConsoleHelpers.cheatsheets
end

# == MODEL TOOLS ==
# These helpers were migrated from console_model_tools.rb to ensure model utilities
# like nested_classes and model summaries are always available when console_helper is loaded.
disable_return_printing if defined?(disable_return_printing)
puts "\n🚀🚀🚀 Loading console_helper.rb — version #{CONSOLE_HELPER_VERSION} 🚀🚀🚀\n"

module ModelInfo
  def association_info
    associations = self.class.reflect_on_all_associations
    info = {}

    associations.each do |association|
      info[association.name] = {
        type: association.macro,
        class_name: association.klass.name
      }
    end

    info
  end
  alias_method :ass, :association_info

  def ass_counts
    klass_var = self.class.name.underscore
    association_info.map do |name, _details|
      count = begin
        assoc = self.send(name)
        assoc.respond_to?(:count) ? assoc.count : (assoc ? 1 : 0)
      rescue
        0
      end
      snippet = "#{klass_var}_#{name} = #{klass_var}.#{name}"
      if count > 0
        [name, [count, snippet]]
      else
        [name, 0]
      end
    end.to_h
  end

  # Returns a hash of association names to their associated objects
  def association_objects
    association_info.keys.index_with { |k| self.send(k) }
  end
  alias_method :ass_objects, :association_objects
end


class Object
  include ModelInfo
end

# Method to fetch subclasses of a module or class
Module.class_eval do
  def nested_classes
    ObjectSpace.each_object(Class).select do |klass|
      begin
        klass.name && klass.name.start_with?("#{self.name}::") &&
          klass.name.count(':') == self.name.count(':') + 2
      rescue StandardError => e
        puts "Error processing class #{klass}: #{e}"
        false
      end
    end
  end

  alias :nc :nested_classes
end



require 'open-uri'

def get_helper(name)
  if name.nil? || name.to_s.strip.empty?
    puts "⚠️  You must pass a name. Try: gh \"workflow\""
    return
  end

  base = name.to_s.strip

  candidates = [
    "#{base}",
    "#{base}.rb",
    "#{base}_helper.rb"
  ]

  loaded = false
  candidates.each do |file|
    timestamp = (Time.now.to_f * 1000).to_i
  url = "https://raw.githubusercontent.com/gavin-zipline/console-helpers/main/#{file}?nocache=#{timestamp}"
    puts "📡 Trying #{file}..."
    begin
      code = URI.open(url).read
      eval(code)
      puts "✅ Loaded #{file} from GitHub repo"
      loaded = true
      break
    rescue OpenURI::HTTPError
      next
    rescue NameError => e
      puts "💥 NameError while loading #{file}: #{e.message}"
      raise
    rescue StandardError => e
      puts "💥 Error loading #{file}: #{e.class} - #{e.message}"
      break
    end
  end

  puts "❌ Repo file not found for any candidate: #{candidates.join(', ')}" unless loaded
end
alias gh get_helper

begin
  gh "team"
rescue => e
  puts "❌ Failed to load team: #{e.message}"
end

begin
  gh "user"
rescue => e
  puts "❌ Failed to load user: #{e.message}"
end

class Object
  def dates
    return {} unless respond_to?(:column_for_attribute)

    self.class.columns.each_with_object({}) do |column, hash|
      if [:date, :datetime, :timestamp].include?(column.type)
        hash[column.name] = send(column.name)
      end
    end
  end
end

# Define a mock link_to method for console output
def link_to(name, _path)
  # Just return the name in plain text for console output
  name
end

# Method to find tenant by record ID and class
def find_tenant(id, klass)
  original_tenant = Apartment::Tenant.current

  Apartment.tenant_names.each do |tenant|
    Apartment::Tenant.switch!(tenant)
    record = klass.find_by(id: id)
    if record
      Apartment::Tenant.switch!(original_tenant)
      return tenant
    end
  end

  Apartment::Tenant.switch!(original_tenant)
  nil
end

# Service Account Impersonation Methods
# Useful for debugging production issues where you can't login as a specific user
def service_account_impersonator(user_or_reset)
  service_user = User.service_user

  # Handle reset case
  if user_or_reset == :reset || user_or_reset == 'reset'
    return puts "❌ No impersonation state found" unless @impersonation_state

    state = @impersonation_state
    original_permissions = state[:original_permissions]
    original_team_memberships = state[:original_team_memberships]
    original_security_role = state[:original_security_role]
    user_to_impersonate = state[:user_to_impersonate]

    puts "=== Restoring Service Account ==="
    puts "Restoring #{service_user.name} from impersonation as #{user_to_impersonate.name}"

    # Restore original state
    service_user.permissions.clear
    original_permissions.each { |permission| service_user.permissions << permission }

    service_user.team_memberships.destroy_all
    original_team_memberships.each do |tm|
      service_user.team_memberships.create!(team: tm.team, role: tm.role)
    end

    service_user.update!(security_role: original_security_role)

    puts "✅ Service account restored to original state"
    puts "  - Permissions: #{service_user.permissions.count}"
    puts "  - Team memberships: #{service_user.team_memberships.count}"
    puts "  - Security role: #{service_user.security_role&.name || 'none'}"
    @impersonation_state = nil

    # Set global variables to service account
    user = User.service_user
    user_context = User.service_user.team_memberships.first&.to_user_context
    puts "  - Set global user and user_context variables"

    return service_user
  end

  # Handle impersonation case
  user_to_impersonate = user_or_reset
  original_permissions = service_user.permissions.to_a
  original_team_memberships = service_user.team_memberships.to_a
  original_security_role = service_user.security_role

  puts "=== Service Account Impersonation ==="
  puts "Impersonating as: #{user_to_impersonate.name} (ID: #{user_to_impersonate.id})"
  puts "Service user: #{service_user.name} (ID: #{service_user.id})"
  puts "Original service permissions: #{service_user.permissions.count}"
  puts "Original service team memberships: #{service_user.team_memberships.count}"
  puts "Original service security role: #{original_security_role&.name || 'none'}"
  puts ""
  puts "User to impersonate permissions: #{user_to_impersonate.permissions.count}"
  puts "User to impersonate team memberships: #{user_to_impersonate.team_memberships.count}"
  puts "User to impersonate security role: #{user_to_impersonate.security_role&.name || 'none'}"

  # Store original state for restoration
  @impersonation_state = {
    service_user: service_user,
    original_permissions: original_permissions,
    original_team_memberships: original_team_memberships,
    original_security_role: original_security_role,
    user_to_impersonate: user_to_impersonate
  }

  # Clear and copy permissions
  service_user.permissions.clear
  user_to_impersonate.permissions.each { |permission| service_user.permissions << permission }

  # Clear and copy team memberships
  service_user.team_memberships.destroy_all
  user_to_impersonate.team_memberships.each do |tm|
    service_user.team_memberships.create!(team: tm.team, role: tm.role)
  end

  # Copy security role
  service_user.update!(security_role: user_to_impersonate.security_role)

  puts ""
  puts "✅ Service account now impersonating #{user_to_impersonate.name}"
  puts "  - Permissions: #{service_user.permissions.count}"
  puts "  - Team memberships: #{service_user.team_memberships.count}"
  puts "  - Security role: #{service_user.security_role&.name || 'none'}"
  puts ""
  puts "Use service_account_impersonator(:reset) when done"

  # Set global variables to service account
  user = User.service_user
  user_context = User.service_user.team_memberships.first&.to_user_context
  puts "  - Set global user and user_context variables"

  service_user
end

# Method to humanize rules for a given object
def humanize_rules(object)
  if object.respond_to?(:rules)
    rules_for_display(object, object.rules)
  else
    "The provided object does not have rules"
  end
rescue StandardError => e
  "Error humanizing rules: #{e.message}"
end

class Array
  def chrono
    return unless all? { |element| element.is_a?(Audited::Audit) }

    sort_by(&:created_at).each do |audit|
      changes_description = audit.audited_changes.map do |attribute, values|
        old_value, new_value = values
        "#{attribute} was changed from #{old_value.nil? ? 'nil' : old_value.inspect} to #{new_value.inspect}"
      end.join(' and ')

      created_at_local = audit.created_at.getlocal('-08:00') # Adjusting to PST (UTC-8)
      created_at_formatted = created_at_local.strftime("%A, %b %d, %Y at %I:%M %p %Z")

      puts "- On #{created_at_formatted}, #{changes_description}."
    end
  end
end

# Method to calculate age
def age(attribute = :created_at)
  created_at = send(attribute)
  return "Unknown date" unless created_at

  "It's #{ActionView::Base.new.distance_of_time_in_words(created_at, Time.current)} old."
end

# Class Communication modifications for task views
class Communication < ApplicationRecord
  def task_view
    tasks.map{ |t| [t.id, t.title, t.type, t.due_on] }
  end
  def task_view_ids
    tasks.map{ |t| t.id }
  end
end

# Base class ApplicationRecord for short_view
class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  def short_view
    max_length = 100
    max_distribution_items = 1  # Show only a summary for distribution
    max_teams_to_show = 5  # Number of teams to display before truncation

    truncate_value = lambda do |value, trunc_max_length, trunc_max_array_items|
      if value.is_a?(String) && value.length > max_length
        "#{value[0...trunc_max_length]}..."
      elsif value.is_a?(Array)
        if value.all? { |item| item.is_a?(Hash) }
          value.map { |hash| hash.transform_values { |v| truncate_value.call(v, trunc_max_length, trunc_max_array_items) } }.first(trunc_max_array_items)
        else
          value.first(trunc_max_array_items)
        end
      elsif value.is_a?(Hash)
        value.transform_values { |v| truncate_value.call(v, trunc_max_length, trunc_max_array_items) }
      else
        value
      end
    end

    attributes.transform_values do |value|
      case
      when value.is_a?(Array) && value == attributes['recipients']
        max_recipients = 10
        value.first(max_recipients) + (value.size > max_recipients ? ["..."] : [])
      when value.is_a?(Array) && value == attributes['distribution']
        value.first(max_distribution_items).map do |dist|
          total_teams_count = dist['teams']&.size || 0
          {
            "id" => dist['id'],
            "ref" => dist['ref'],
            "name" => dist['name'],
            "type" => dist['type'],
            "teams" => dist['teams'] ? dist['teams'].first(max_teams_to_show) + (total_teams_count > max_teams_to_show ? ["... (#{total_teams_count} teams total)"] : []) : [],
            "action" => dist['action'],
            "display_type" => dist['display_type'],
            "name_with_reference_number" => dist['name_with_reference_number']
          }
        end + (value.size > max_distribution_items ? ["..."] : [])
      else
        truncate_value.call(value, max_length, 5)
      end
    end
  end
end

# Class Audited::Audit modifications for short_view
class Audited::Audit
  def short_view
    max_length = 100
    max_distribution_items = 1
    max_teams_to_show = 5

    truncate_value = lambda do |value, trunc_max_length, trunc_max_array_items|
      if value.is_a?(String) && value.length > max_length
        "#{value[0...trunc_max_length]}..."
      elsif value.is_a?(Array)
        if value.all? { |item| item.is_a?(Hash) }
          value.map { |hash| hash.transform_values { |v| truncate_value.call(v, trunc_max_length, trunc_max_array_items) } }.first(trunc_max_array_items)
        else
          value.first(trunc_max_array_items)
        end
      elsif value.is_a?(Hash)
        value.transform_values { |v| truncate_value.call(v, trunc_max_length, trunc_max_array_items) }
      else
        value
      end
    end

    audited_changes_summarized = audited_changes.transform_values do |value|
      if value.is_a?(Array) && value.first.is_a?(Hash) && value.first['teams']
        value.first(max_distribution_items).map do |dist|
          total_teams_count = dist['teams']&.size || 0
          {
            "id" => dist['id'],
            "ref" => dist['ref'],
            "name" => dist['name'],
            "type" => dist['type'],
            "teams" => dist['teams'] ? dist['teams'].first(max_teams_to_show) + (total_teams_count > max_teams_to_show ? ["... (#{total_teams_count} teams total)"] : []) : [],
            "action" => dist['action'],
            "display_type" => dist['display_type'],
            "name_with_reference_number" => dist['name_with_reference_number']
          }
        end + (value.size > max_distribution_items ? ["..."] : [])
      else
        truncate_value.call(value, max_length, 5)
      end
    end

    {
      id: self.id,
      auditable_id: self.auditable_id,
      auditable_type: self.auditable_type,
      associated_id: self.associated_id,
      associated_type: self.associated_type,
      user_id: self.user_id,
      user_type: self.user_type,
      action: self.action,
      audited_changes: audited_changes_summarized,
      version: self.version,
      created_at: self.created_at,
      remote_address: self.remote_address
    }
  end
end

# Array method to find duplicates
class Array
  def dupes
    string_count = Hash.new(0)
    each { |str| string_count[str] += 1 }
    string_count.select { |_, count| count > 1 }.keys
  end
end

# Methods for console functionality

def run_history_item(index)
  cmd = Readline::HISTORY.to_a[index.to_i]
  print "execute #{cmd} (y/n): "
  confirm = STDIN.gets.strip.downcase
  return puts("❌ Cancelled.") unless confirm == 'y'
  puts "🏃 Executing..."
  eval(cmd)
end
alias :rhi :run_history_item

# List the last N history items, truncating each to 3 lines with “...” if longer
def list_recent_history(count = 25)
  puts "\n🕘  Last #{count} IRB Commands:\n\n"
  total = Readline::HISTORY.length
  Readline::HISTORY.to_a.last(count).each_with_index do |cmd, i|
    index  = total - count + i
    lines  = cmd.lines
    prefix = "#{index.to_s.rjust(3)}: "

    # Print up to 3 lines, indenting subsequent lines, add ellipsis if truncated
    lines.first(3).each_with_index do |line, idx|
      if idx.zero?
        puts "#{prefix}#{line.chomp}"
      else
        puts "#{' ' * prefix.length}#{line.chomp}"
      end
    end
    puts "#{' ' * prefix.length}..." if lines.size > 3
  end
  nil
end
alias :lrh :list_recent_history

# Show the full content of a single history item by its index
def show_history_item(index)
  cmd = Readline::HISTORY.to_a[index.to_i]
  puts "\n🔍 Command History Item [#{index}]:\n\n"
  puts cmd
  nil
end
alias :shi :show_history_item

## ...existing code...


SHORTCUTS = {
  org: -> { Organization.current.shortname },
  usc: -> { unsafe_console! },
  sc:  -> { safe_console! },
  erp: -> { enable_return_printing },
  drp: -> { disable_return_printing },
  lv:  -> { local_variables },
  rl:  -> { ResourceLibrary },
  dpp: -> { DynamicProvisioning::Pipeline },
  dp: -> { DynamicProvisioning },
}.freeze

SHORTCUTS.each do |method_name, proc_blk|
  define_method(method_name, &proc_blk)
end

# Switch orgs. With no argument, falls back to the interactive company helper.
# With a shortname, switches directly so the call is safe inside a pasted block
# (the interactive prompt would otherwise eat the next line of the paste).
def so(shortname = nil)
  return switch_org if shortname.nil?

  choice = shortname.to_s.strip.downcase
  return false unless handle_choice(choice)

  asciify(choice)
  true
end

def variablize_class_map
  {
    "users"               => User,
    "teams"               => Team,
    "groups"              => Discuss::Group,
    "resources"           => ResourceLibrary::Resource,
    "documents"           => ResourceLibrary::Document,
    "pipelines"           => DynamicProvisioning::Pipeline,
    "indexes"             => DynamicProvisioning::Index,
    "roles"               => Role,
    "role_aliases"        => RoleAlias,
    "security_levels"     => SecurityLevel,
    "security_level_aliases" => SecurityLevelAlias,
    "organization_roles"  => OrganizationRole,
    "departments"         => Department,
    "branches"            => Branch,
    "permissions"         => Permission,
    "team_types"          => TeamType,
    "communications"      => Communication,
    "recurring_templates" => RecurringCommunicationTemplate,
    "communication_templates" => CommunicationTemplate,
    "communication_read_receipts" => CommunicationReadReceipt,
    "courses"             => Learning::Course,
    "punches"             => Punch,
    "schedule"            => Schedule,
    "metrics"             => ExternalTeamMetric,
    "work_orders"         => WorkOrder,
    "assessments"         => Audit::Assessment,
    "audit_results"       => Audit::Result,
    "enrollments"         => Enrollment,
    "tracks"              => Track,
    "certifications"      => Certification,
    "events"              => Event,
    "files"               => Alignment::File,
    "categories"          => Communication::Category,
    "email_workflows"     => Workflow
  }
end

# Try to guess a class from the URL segment
def guess_class_from_path(type)
  class_map = variablize_class_map
  return class_map[type] if class_map.key?(type)

  # Try to find an ActiveRecord class whose name matches the singularized type
  candidates = ActiveRecord::Base.descendants.select do |klass|
    klass.name.demodulize.downcase == type.singularize.downcase
  end

  if candidates.size == 1
    candidates.first
  elsif candidates.size > 1
    puts "⚠️  Multiple guesses for '#{type}': #{candidates.map(&:name).join(', ')}"
    candidates.first
  else
    puts "⚠️  Could not guess a model class for '#{type}'"
    nil
  end
end

def variablize_url(url)
  uri = URI.parse(url)
  path_segments = uri.path.split("/").reject(&:empty?)
  query = Rack::Utils.parse_query(uri.query)

  output = []

  # Handle special case: communication task
  if query["team_task_id"] && query["communication_reference_id"]
    output << "communication_reference_id = '#{query["communication_reference_id"]}'"
    output << "team_task_id = '#{query["team_task_id"]}'"
    output << "communication = Communication.find_by(reference_id: communication_reference_id)"
    output << "task = communication.tasks.find { |t| t.id == team_task_id }"
    return puts output.join("\n")
  end

  class_map = variablize_class_map
  last_uuid = path_segments.reverse.find { |seg| seg =~ /^[0-9a-f\-]{8,}$/i || seg.length > 8 }

  if last_uuid
    index = path_segments.index(last_uuid)
    type = path_segments[index - 1]
    var_name = "#{type.singularize}_id"

    output << "#{var_name} = '#{last_uuid}'"

    model_class = class_map[type] || guess_class_from_path(type)
    if model_class
      model_var = model_class.to_s.split("::").last.underscore
      finder = if model_class.to_s.start_with?("ResourceLibrary", "Discussion")
                 ".for_permalink_or_id(#{var_name})"
               else
                 ".find(#{var_name})"
               end
      output << "#{model_var} = #{model_class}#{finder}"
    end
  else
    output << "❌  Couldn't parse type and ID from URL."
  end

  puts output.join("\n")
end

# Batch version of variablize_url
def variablize_urls(urls)
  urls.each do |url|
    puts "\n# From: #{url}"
    variablize_url(url)
  end
end

# Extract URLs from clipboard and variablize them
def variablize_urls_from_clipboard
  urls = `pbpaste`.scan(%r{https?://[^\s]+})
  variablize_urls(urls)
end

# Remove unnecessary commands from the console history
index_to_truncate = Readline::HISTORY.to_a.rindex { |cmd| cmd == 'puts "START"' }
if index_to_truncate
  commands_to_remove = Readline::HISTORY.length - (index_to_truncate - 1)
  commands_to_remove.times { Readline::HISTORY.pop }
end

class Hash
  def pretty
    sort_by { |k, _| k.to_s }.each do |key, value|
      puts "#{key}: #{value}"
    end
  end
end

# == DATA AGE / TENANT IDENTITY ==
#
# `da` answers two separate questions and labels which is which:
#
#   IDENTITY  — is this the real tenant, or a stub / frozen clone / empty schema?
#               Answered by ROW COUNTS. A stub has single-digit users and no content.
#   FRESHNESS — how current is the data?
#               Answered by MAX TIMESTAMPS, sampled across several models.
#
# The old single-source, single-timestamp version could not tell either question
# apart from a healthy tenant, and failed in both directions:
#
#   Over-reporting  — INT-2397 (2026-08-18): the staging `kavehome` schema is a
#                     pre-migration stub (0 training files, 2 users), but
#                     Audited::Audit carried a 2026-07-31 timestamp from the clone
#                     itself. `da` printed "current as of 2026-07-31 (18 days ago)"
#                     and read as a live tenant snapshot. Kave Home exists twice —
#                     `internal` on primary, `customer` on eu-west-1 — and staging
#                     clones primary, so staging gets the stub.
#   Under-reporting — Draco does not replicate EventStream::Event, so the fallback
#                     to Audited::Audit reported data far staler than it was and
#                     usable data got dismissed.
#
# Sampling several models fixes both: disagreement between sources is itself the
# signal, so it is printed rather than collapsed into one number.

DATA_AGE_COUNT_CAP        = 1_000  # bounded COUNT ceiling — "1000+" is enough to settle identity
DATA_AGE_MIN_LIVE_USERS   = 10     # fewer than this => never LIVE
DATA_AGE_PROBE_TIMEOUT_MS = 3_000  # per-query statement_timeout
DATA_AGE_TIME_BUDGET      = 12.0   # total seconds for timestamp probes; the rest are skipped
DATA_AGE_SKEW_DAYS        = 7      # source disagreement wider than this gets called out

# [model name, role, note]
DATA_AGE_PROBES = [
  ["User",               :identity,  nil],
  ["Team",               :identity,  nil],
  ["Communication",      :freshness, nil],
  ["Task",               :volume,    "count only — team_tasks has no created_at index"],
  ["EventStream::Event", :freshness, "not replicated on Draco"],
  ["Audited::Audit",     :freshness, "can carry clone-artifact timestamps — see INT-2397"]
].freeze

# Timestamp probes run in this order so the best freshness signals get the budget
# first. Task is absent on purpose: MAX(created_at) on team_tasks is a sequential
# scan over the largest table in the schema and would burn the whole budget.
DATA_AGE_TIME_ORDER = ["Communication", "EventStream::Event", "Audited::Audit", "User", "Team"].freeze

def _da_klass(name)
  Object.const_get(name)
rescue StandardError
  nil
end

# Read-only probe with a hard statement timeout, so one slow table degrades to
# "timeout" in the table instead of hanging a session-opening command.
def _da_guarded(&block)
  ActiveRecord::Base.transaction(requires_new: true) do
    ActiveRecord::Base.connection.execute("SET LOCAL statement_timeout = #{DATA_AGE_PROBE_TIMEOUT_MS.to_i}")
    block.call
  end
rescue ActiveRecord::QueryCanceled
  :timeout
rescue StandardError => e
  e
end

def _da_age_short(ts)
  return "—" if ts.nil?

  diff = (Time.current - ts).to_i
  return "#{diff}s" if diff < 60
  return "#{diff / 60}m" if diff < 3600
  return "#{diff / 3600}h" if diff < 86_400

  "#{diff / 86_400}d"
end

def _da_age_words(ts)
  diff = (Time.current - ts).to_i
  return "#{diff} seconds" if diff < 60
  return "#{diff / 60} minutes" if diff < 3600
  return "#{diff / 3600} hours" if diff < 86_400

  "#{diff / 86_400} days"
end

def _da_stamp(value)
  case value
  when nil       then "—"
  when :timeout  then "timeout"
  when :skipped  then "skipped"
  when :nocolumn then "n/a"
  when StandardError then "error"
  else "#{value.utc.strftime('%Y-%m-%d %H:%M')} (#{_da_age_short(value)})"
  end
end

def _da_rows(probe)
  return "—" if probe[:count].nil?
  return "error" if probe[:count].is_a?(StandardError) || probe[:count] == :timeout

  probe[:capped] ? "#{DATA_AGE_COUNT_CAP}+" : probe[:count].to_s
end

def _da_time?(value)
  value.is_a?(Time) || (defined?(ActiveSupport::TimeWithZone) && value.is_a?(ActiveSupport::TimeWithZone))
end

# [[source name, timestamp], ...] for every probe that produced a usable time.
def _da_stamps_for(probes)
  probes.flat_map { |p| [[p[:name], p[:created]], [p[:name], p[:updated]]] }
        .select { |_, v| _da_time?(v) }
end

def _da_newest(probe)
  return nil if probe.nil?

  [probe[:created], probe[:updated]].select { |v| _da_time?(v) }.max
end

def _da_verdict(counts)
  users = counts["User"]
  teams = counts["Team"]
  comms = counts["Communication"]
  return :uncertain unless users.is_a?(Integer) && comms.is_a?(Integer)

  return :empty if users.zero? && comms.zero? && (!teams.is_a?(Integer) || teams.zero?)
  return :stub  if users < DATA_AGE_MIN_LIVE_USERS || comms.zero?

  :live
end

DATA_AGE_VERDICT_LABELS = {
  live:      "LIVE TENANT",
  stub:      "STUB",
  empty:     "EMPTY",
  uncertain: "UNCERTAIN"
}.freeze

def _da_identity_line
  org = begin
    Organization.current
  rescue StandardError
    nil
  end
  schema = begin
    Apartment::Tenant.current
  rescue StandardError
    "unknown"
  end
  [org, schema]
end

# fast: true skips every timestamp probe and answers identity only.
def data_age(fast: false)
  started = Time.now
  org, schema = _da_identity_line

  probes = DATA_AGE_PROBES.map do |name, role, note|
    { name: name, role: role, note: note, klass: _da_klass(name) }
  end

  # --- IDENTITY: bounded counts. Always run; cheap and the only reliable stub test.
  probes.each do |probe|
    if probe[:klass].nil?
      probe[:count] = nil
      probe[:note] = [probe[:note], "model not defined in this tenant"].compact.join("; ")
      next
    end

    result = _da_guarded { probe[:klass].limit(DATA_AGE_COUNT_CAP).count }
    probe[:count]  = result
    probe[:capped] = result.is_a?(Integer) && result >= DATA_AGE_COUNT_CAP
  end

  counts = probes.each_with_object({}) { |p, h| h[p[:name]] = p[:count] }
  verdict = _da_verdict(counts)

  # --- FRESHNESS: best-effort max timestamps under a shared budget.
  probes.each { |p| p[:created] = p[:updated] = (fast ? :skipped : nil) }

  unless fast
    DATA_AGE_TIME_ORDER.each do |name|
      probe = probes.find { |p| p[:name] == name }
      next if probe.nil? || probe[:klass].nil?

      %i[created updated].each do |field|
        column = "#{field}_at"

        unless probe[:klass].column_names.include?(column)
          probe[field] = :nocolumn
          next
        end

        if Time.now - started > DATA_AGE_TIME_BUDGET
          probe[field] = :skipped
          next
        end

        probe[field] = _da_guarded { probe[:klass].maximum(column) }
      end
    end
  end

  # --- OUTPUT
  label   = DATA_AGE_VERDICT_LABELS[verdict]
  org_type = org&.type
  title   = org ? "#{org.shortname} — #{org.full_name}" : schema.to_s
  header  = "  #{label}   #{title}#{org_type ? "  [#{org_type}]" : ''}"
  rule    = "=" * [header.length + 2, 78].max

  puts ""
  puts rule
  puts header
  puts rule

  meta = ["schema: #{schema}", "env: #{Rails.env}"]
  meta << "org id: #{org.id}" if org
  meta << "go-live: #{org.go_live_on}" if org&.go_live_on
  meta << "DISABLED" if org.respond_to?(:disabled?) && org&.disabled?
  puts "  #{meta.join('   ')}"

  if org
    puts "  public.organizations cached counters: user_count=#{org.user_count.inspect} " \
         "store_count=#{org.store_count.inspect}  (maintained outside this schema — compare to ROWS below)"
  end

  row_format = "  %-20s %-10s %-7s %-23s %-23s"
  puts ""
  puts format(row_format, "MODEL", "ROLE", "ROWS", "NEWEST created_at", "NEWEST updated_at")
  puts "  #{'-' * 83}"
  probes.each do |probe|
    puts format(
      row_format,
      probe[:name],
      probe[:role],
      _da_rows(probe),
      _da_stamp(probe[:created]),
      _da_stamp(probe[:updated])
    )
  end

  notes = probes.reject { |p| p[:note].to_s.empty? }
  unless notes.empty?
    puts ""
    notes.each { |p| puts "  · #{p[:name]}: #{p[:note]}" }
  end

  # Headline freshness: newest timestamp seen anywhere, named by its source.
  stamps = _da_stamps_for(probes)
  puts ""
  if stamps.empty?
    puts "  Freshness: unknown — no usable timestamp landed#{fast ? ' (fast: true skips timestamps)' : ''}."
  else
    src, newest = stamps.max_by { |_, v| v }
    puts "  Freshness: newest row anywhere is #{newest.utc.strftime('%Y-%m-%d %H:%M:%S UTC')} " \
         "(#{_da_age_words(newest)} ago) [#{src}]."

    # Skew is measured across freshness-role sources only. Comparing them to User
    # or Team would fire on every healthy tenant — "no new teams in 9 days" is normal.
    fresh = _da_stamps_for(probes.select { |p| p[:role] == :freshness })
    if fresh.length > 1
      _, f_new = fresh.max_by { |_, v| v }
      _, f_old = fresh.min_by { |_, v| v }
      if (f_new - f_old) > DATA_AGE_SKEW_DAYS.days
        puts "  ⚠️  Freshness sources disagree by #{((f_new - f_old) / 1.day).round} days — " \
             "do not trust a single row above."
      end
    end

    audit_ts = _da_newest(probes.find { |p| p[:name] == "Audited::Audit" })
    cont_ts  = _da_newest(probes.find { |p| p[:name] == "Communication" })
    if audit_ts && (cont_ts.nil? || (audit_ts - cont_ts) > DATA_AGE_SKEW_DAYS.days)
      puts "  ⚠️  Audit trail is newer than tenant content. That is the clone-artifact shape " \
           "from INT-2397 — the audit timestamp is probably the copy, not tenant activity."
    end
  end

  if org && org_type && org_type != "customer"
    puts ""
    puts "  ⚠️  This org is type `#{org_type}`, not `customer`. A live customer tenant of the same"
    puts "      shortname may exist on another cluster (Kave Home: `internal` on primary,"
    puts "      `customer` on eu-west-1). Check DbListOrganizationsTool / the admin Jumper before"
    puts "      concluding anything about the customer from this schema."
  end

  if verdict != :live
    puts ""
    puts "  ⚠️  #{label} — do NOT draw customer conclusions from this schema. " \
         "Threshold: <#{DATA_AGE_MIN_LIVE_USERS} users or 0 communications is never LIVE."
  end

  puts ""
  puts "  Probed in #{(Time.now - started).round(1)}s. Counts are capped at #{DATA_AGE_COUNT_CAP} (\"#{DATA_AGE_COUNT_CAP}+\" means at least that many)."
  puts "  LIMIT: this is a tenant-level check only. It cannot tell you whether the domain you"
  puts "         care about has data — INT-2397's actual blocker was Training::File.count == 0"
  puts "         on a schema that looked fine. Count your own model before concluding."
  puts ""
  verdict
end
alias :da :data_age

$last_active = Time.now
IRB.conf[:IRB_RC] = proc { $last_active = Time.now }

def keep_alive
  Thread.new do
    loop do
      sleep 60
      break if Time.now - $last_active > 7200
      print "."
    end
  end
end
keep_alive

enable_return_printing if defined?(enable_return_printing)
cheatsheet
