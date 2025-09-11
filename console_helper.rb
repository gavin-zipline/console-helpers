# Console Helper — your safe bootstrap + generic helper methods
# Loads foundational utilities, shortcuts, and the get_helper system
# Use `gh("helper_name")` to dynamically load subject-specific helpers (see README.md)
# == LOADED HELPERS REGISTRY ==
# Tracks loaded helpers, their versions, and cheatsheet procs
module ConsoleHelpers
  @@loaded_helpers = {}

  # Register a helper when loaded
  def self.register_helper(helper_name, version, cheatsheet_proc)
    @@loaded_helpers[helper_name] = {
      version: version,
      cheatsheet: cheatsheet_proc
    }
  end

  # List loaded helpers with version numbers
  def self.helpers
    @@loaded_helpers.map { |name, info| "#{name} (v#{info[:version]})" }
  end

  # Aggregate cheatsheets for all loaded helpers
  def self.cheatsheets
    @@loaded_helpers.map do |name, info|
      "--- #{name} (v#{info[:version]}) ---\n" + info[:cheatsheet].call.to_s
    end.join("\n\n")
  end
end

# == MODEL TOOLS ==
# These helpers were migrated from console_model_tools.rb to ensure model utilities
# like nested_classes and model summaries are always available when console_helper is loaded.
disable_return_printing
CONSOLE_HELPER_VERSION = "0.3.16"
puts "🚀🚀🚀 Loading console_helper.rb — version #{CONSOLE_HELPER_VERSION} 🚀🚀🚀"

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
end

class Object
  include ModelInfo
end

Module.class_eval do
  def nested_classes
    ObjectSpace.each_object(Class).select do |klass|
      begin
        klass.name && klass.name.start_with?("#{self.name}::") && klass.name.count(':') == self.name.count(':') + 2
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

  candidates.each do |file|
    timestamp = (Time.now.to_f * 1000).to_i
    url = "https://gist.githubusercontent.com/gavin-zipline/dcfbfc592ea0e4551453176ff3851ee8/raw/#{file}?nocache=#{timestamp}"
    puts "📡 Trying #{file}..."
    begin
      code = URI.open(url).read
    eval(code)
    puts "✅ Loaded #{file} from Gist"
    break
    rescue OpenURI::HTTPError
    next
    rescue NameError => e
    puts "💥 NameError while loading #{file}: #{e.message}"
    break
    rescue StandardError => e
    puts "💥 Error loading #{file}: #{e.class} - #{e.message}"
    break
    end
  end

  puts "❌ Gist file not found for any candidate: #{candidates.join(', ')}"
end
alias gh get_helper

begin
  gh "git_issue"
rescue => e
  puts "❌ Failed to load git_issue: #{e.message}"
end

begin
  gh "team"
rescue => e
  puts "❌ Failed to load team: #{e.message}"
end

begin
  gh "user"
  puts "✅ user helper loaded"
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
    max_recipients = 10  # Increase the limit for recipients
    max_distribution_items = 1  # Show only a summary for distribution
    max_teams_to_show = 5  # Number of teams to display before truncation

    # Helper method to truncate values
    truncate_value = lambda do |value, max_length, max_array_items|
      if value.is_a?(String) && value.length > max_length
        "#{value[0...max_length]}..."
      elsif value.is_a?(Array)
        if value.all? { |item| item.is_a?(Hash) }
          value.map { |hash| hash.transform_values { |v| truncate_value.call(v, max_length, max_array_items) } }.first(max_array_items)
        else
          value.first(max_array_items)
        end
      elsif value.is_a?(Hash)
        value.transform_values { |v| truncate_value.call(v, max_length, max_array_items) }
      else
        value
      end
    end

    # Customize handling for recipients and distribution
    attributes.transform_values do |value|
      case
      when value.is_a?(Array) && value == attributes['recipients']
        value.first(max_recipients) + (value.size > max_recipients ? ["..."] : [])
      when value.is_a?(Array) && value == attributes['distribution']
        # Summarize the distribution
        value.first(max_distribution_items).map do |dist|
          total_teams_count = dist['teams']&.size || 0  # Safeguard against nil
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
    max_recipients = 10  # For recipients-like arrays in changes
    max_distribution_items = 1  # For summarizing distribution-like data
    max_teams_to_show = 5  # Number of teams to display before truncation

    # Helper method to truncate values
    def truncate_value(value, max_length, max_array_items)
      if value.is_a?(String) && value.length > max_length
        "#{value[0...max_length]}..."
      elsif value.is_a?(Array)
        if value.all? { |item| item.is_a?(Hash) }
          value.map { |hash| hash.transform_values { |v| truncate_value(v, max_length, max_array_items) } }.first(max_array_items)
        else
          value.first(max_array_items)
        end
      elsif value.is_a?(Hash)
        value.transform_values { |v| truncate_value(v, max_length, max_array_items) }
      else
        value
      end
    end

    # Customize handling for `audited_changes`
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
        truncate_value(value, max_length, 5)
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
      audited_changes: audited_changes_summarized, # Truncated and summarized `audited_changes`
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
  puts "• variablize_url(url) → Generate ID + find line for one URL"
  puts "• variablize_urls([url1, url2, ...]) → Same for multiple"
  puts "• variablize_urls_from_clipboard → Extract URLs from clipboard and variablize"
end


SHORTCUTS = {
  org: -> { Organization.current.shortname },
  so:  -> { switch_org },
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

# Conditionally invoke the appropriate cheatsheet, if available
if respond_to?(:console_cheatsheet)
  console_cheatsheet
elsif respond_to?(:cheatsheet)
  cheatsheet
else
  puts "ℹ️  No cheatsheet method found in console_helper.rb"
end
enable_return_printing
