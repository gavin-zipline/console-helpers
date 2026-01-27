
###############################################################################
# Pipeline Helper
# -----------------------------------------------------------------------------
# Purpose: Console/debugging helpers for DynamicProvisioning pipelines.
# Usage: Load via `gh("pipeline")` or `gh("pipelines")` then use `pipeline_cheatsheet` for docs.
# Safety: Read-only, no destructive operations.
#
# Structure: Version constant, cheatsheet, registration, aliases, shortcuts, core methods, cheatsheet call.
###############################################################################

PIPELINE_HELPER_VERSION = "0.2.1"
require 'globalid'

# -----------------------------------------------------------------------------
# Cheatsheet (usage docs)
# -----------------------------------------------------------------------------
def pipeline_cheatsheet
  puts   "\n🚀🚀🚀 PIPELINE HELPER — VERSION #{PIPELINE_HELPER_VERSION} 🚀🚀🚀"
  puts "\n📘 Pipeline Helper Cheatsheet:"
  puts "\n📘 Pipeline Instance Methods:"
  puts "• pipeline.summary"
  puts "  → Pretty one-page summary of pipeline configuration, sources, transformations, and targets."
  puts "  → One-liner reminder for how to run the pipeline with RunPipelineJob."
  puts "• pipeline.generate"
  puts "  → Enqueues the pipeline to run via background job."
  puts "• pipeline.target_objects"
  puts "  → Returns an array of resolved target model instances."
  puts "• pipeline.source_object"
  puts "  → Returns the resolved source model instance."
  puts "• pipeline.target_map"
  puts "  → Returns a hash of source objects to target objects (e.g. { Team => DistributionList })."
  puts "\n🔍 Exploration & Listing:"
  puts "• pipelines_list"
  puts "  → Full summary of each pipeline including status, targets, transformations, models, and source type."
  puts "• find_pipelines_targeting(object)"
  puts "  → Given a model instance, return any pipelines that target it."
  puts "\n📥 Usage:"
  puts "• pipeline = DynamicProvisioning::Pipeline.find(\"pipeline-id\")"
  puts "• puts pipeline.summary"
  puts "• puts pipeline.guide"
  puts "• pipeline.generate"
  puts "\n💡 Shortcuts (optional aliases):"
  puts "• dp  = DynamicProvisioning"
  puts "• dpp = DynamicProvisioning::Pipeline"
  puts "• dpt = DynamicProvisioning::Transformation"
  puts "\n🛠️  Source Type Ideas (not yet implemented):"
  puts "• Scope-based: Use existing model scopes"
  puts "• Method Chain: Chain ActiveRecord methods"
  puts "• SQL-based: Direct SQL queries"
  puts "• Association-based: Follow associations from a base record"
  puts "• Currently only SmartQuery sources are supported"
end

# Flexible cheatsheet naming
alias pipeline_helper_cheatsheet pipeline_cheatsheet
alias pipelines_cheatsheet pipeline_cheatsheet
alias pipelines_helper_cheatsheet pipeline_cheatsheet

# Register helper
ConsoleHelpers.register_helper("pipeline", PIPELINE_HELPER_VERSION, method(:pipeline_cheatsheet))

# --------------------------------- shortcuts -------------------------------- #
def dp
  DynamicProvisioning
end

def dpp
  DynamicProvisioning::Pipeline
end

def dpt
  DynamicProvisioning::Transformation
end

def pipeline_helper_version
  puts "🧭 Pipeline Helper Version: #{PIPELINE_HELPER_VERSION}"
  PIPELINE_HELPER_VERSION
end

# -----------------------------------------------------------------------------
# 🛠️ UTILITY METHODS
# -----------------------------------------------------------------------------

# Robust GID parsing (no DB)
def gid_parse(gid_str)
  return { gid: gid_str, app: nil, model: nil, id: nil, valid: false, error: "blank" } if gid_str.nil? || gid_str.to_s.strip.empty?
  begin
    gid = GlobalID.parse(gid_str)
    if gid
      { gid: gid_str, app: gid.app, model: gid.model_name, id: gid.model_id, valid: true, error: nil }
    else
      { gid: gid_str, app: nil, model: nil, id: nil, valid: false, error: "parse_failed" }
    end
  rescue => e
    { gid: gid_str, app: nil, model: nil, id: nil, valid: false, error: e.message }
  end
end

# Optional GID resolution (DB allowed, safe)
def gid_resolve(gid_str)
  parsed = gid_parse(gid_str)
  begin
    obj = GlobalID::Locator.locate(gid_str)
    label = if obj.respond_to?(:name) && obj.name.present?
      obj.name
    elsif obj.respond_to?(:title) && obj.title.present?
      obj.title
    elsif obj.respond_to?(:email) && obj.email.present?
      obj.email
    else
      nil
    end
    parsed.merge(
      located: obj.present?,
      located_class: obj&.class&.name,
      located_id: obj&.id,
      located_label: label
    )
  rescue => e
    parsed.merge(located: false, located_class: nil, located_id: nil, located_label: nil, error: e.message)
  end
end


# Inspect DynamicProvisioning::Target rows for a transformation
def dp_targets(transformation_id:, limit: 20, resolve: false)
  begin
    klass = defined?(DynamicProvisioning::Target) ? DynamicProvisioning::Target : Object.const_get('DynamicProvisioning::Target')
    targets = klass.unscoped.where(transformation_id: transformation_id).order(created_at: :desc).limit(limit)
    targets.map do |t|
      {
        id: t.id,
        transformation_id: t.transformation_id,
        created_at: t.created_at,
        deleted_at: t.deleted_at,
        source: (resolve ? gid_resolve(t.source) : gid_parse(t.source)),
        target: (resolve ? gid_resolve(t.target) : gid_parse(t.target))
      }
    end
  rescue => e
    puts "[dp_targets] Error: #{e.message}"
    []
  end
end

# Convenience wrappers for source/target filtering
def dp_targets_for_source(transformation_id:, source_gid:, limit: 20, resolve: false)
  dp_targets(transformation_id: transformation_id, limit: limit, resolve: resolve).select { |row| row[:source][:gid] == source_gid }
end

def dp_targets_for_target(transformation_id:, target_gid:, limit: 20, resolve: false)
  dp_targets(transformation_id: transformation_id, limit: limit, resolve: resolve).select { |row| row[:target][:gid] == target_gid }
end

# Pretty-printer for GIDs
def pp_gid(gid_str, resolve: false)
  begin
    info = resolve ? gid_resolve(gid_str) : gid_parse(gid_str)
    base = "#{info[:model] || 'Unknown'} #{info[:id] || '-'}"
    if resolve && info[:located_label]
      "#{base} (#{info[:located_label]})"
    else
      base
    end
  rescue => e
    "[invalid GID: #{e.message}]"
  end
end

class DynamicProvisioning::Pipeline
  def to_mermaid_diagram
    <<~DIAGRAM.strip
      ---
      title: Diagram for #{name} Pipeline
      ---
      flowchart-elk LR
      #{transformations.map(&:to_mermaid_class).join("\n")}
      #{requirements.map(&:to_mermaid_relation).join("\n")}
    DIAGRAM
  end

  def generate
    DynamicProvisioning::RunPipelineJob.perform_async(id)
  end

  # Summary: print targets using gid_parse (no DB)
  def summary
    <<~SUMMARY
      ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
      ┃         PIPELINE SUMMARY             ┃
      ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

      Name:        #{name}
      ID:          #{id}
      Active:      #{deleted_at.nil? ? 'Yes' : 'No'}
      Created At:  #{created_at.strftime('%Y-%m-%d %H:%M:%S')}
      Updated At:  #{updated_at.strftime('%Y-%m-%d %H:%M:%S')}

      ── SOURCE ──────────────────────────────
      Type:        #{source&.type&.demodulize || 'N/A'}
      Name:        #{source&.name || 'N/A'}
      Rules:
      #{pretty_rules(source&.configuration&.dig("rules"))}

      ── TRANSFORMATIONS (#{transformations.size}) ─────────────
      #{transformations.map { |t| format_transformation(t) }.join("\n")}

      ── TARGETS (#{targets.size}) ─────────────────────
      #{targets.map { |t|
        src = gid_parse(t.source)
        tgt = gid_parse(t.target)
        "• #{src[:model] || 'Unknown'} #{src[:id]} → #{tgt[:model] || 'Unknown'} #{tgt[:id]}"
      }.join("\n")}
    SUMMARY
  end

  # Verbose summary: print targets using gid_resolve (DB allowed)
  def summary_verbose(limit: 50)
    shown = targets.first(limit)
    <<~SUMMARY
      ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
      ┃         PIPELINE SUMMARY (VERBOSE)   ┃
      ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

      Name:        #{name}
      ID:          #{id}
      Active:      #{deleted_at.nil? ? 'Yes' : 'No'}
      Created At:  #{created_at.strftime('%Y-%m-%d %H:%M:%S')}
      Updated At:  #{updated_at.strftime('%Y-%m-%d %H:%M:%S')}

      ── TARGETS (showing #{shown.size} of #{targets.size}) ─────────────
      #{shown.map { |t|
        src = gid_resolve(t.source)
        tgt = gid_resolve(t.target)
        "• #{src[:model] || 'Unknown'} #{src[:id]}#{src[:located_label] ? " (#{src[:located_label]})" : ""} → #{tgt[:model] || 'Unknown'} #{tgt[:id]}#{tgt[:located_label] ? " (#{tgt[:located_label]})" : ""}"
      }.join("\n")}
    SUMMARY
  end


  def target_objects
    targets.map { |t| GlobalID::Locator.locate(t.target) }.compact
  end

  def source_object
    GlobalID::Locator.locate(source)
  end

  def target_map
    targets.map do |t|
      [GlobalID::Locator.locate(t.source), GlobalID::Locator.locate(t.target)]
    end.to_h
  end
def moderator_rules
  transformations
    .where("data ->> 'target' = ?", 'generator_moderator_rules')
    .pluck(:data)
    .flat_map do |d|
      parsed = JSON.parse(d["template"]) rescue nil
      parsed = JSON.parse(parsed) if parsed.is_a?(String) rescue nil
      parsed.is_a?(Array) ? parsed : []
    end
  end
  def owner_rules
    transformations
      .where("data ->> 'target' = ?", 'generator_owner_rules')
      .pluck(:data)
      .map { |d| JSON.parse(d["template"]) rescue [] }
      .flatten
  end

  def subscriber_rules
    transformations
      .where("data ->> 'target' = ?", 'generator_subscriber_rules')
      .pluck(:data)
      .map { |d| JSON.parse(d["template"]) rescue [] }
      .flatten
  end

  private

  def format_transformation(t)
    case t
    when DynamicProvisioning::Transformation::Interpolation
      "• Interpolation: #{t.data['target']} = #{t.data['template']}"
    when DynamicProvisioning::Transformation::Provisioning
      assoc = t.data["associations"].map { |k, v| "#{k}: #{v}" }.join(", ")
      "• Provisioning: model = #{t.data['model']}, associations = { #{assoc} }"
    else
      "• Unknown Transformation: #{t.type}"
    end
  end

  def extract_gid_id(gid)
    gid.to_s.split('/').last
  end

  def pretty_rules(rules)
    return 'None' unless rules
    rules.map.with_index(1) do |rule, i|
      json = rule.to_json
      json.length > 120 ? "#{i}. #{json[0..120]}..." : "#{i}. #{json}"
    end.join("\n")
  end
end


# ---------------------------------------------------------------------------
# RunContext summary
# ---------------------------------------------------------------------------
class DynamicProvisioning::RunContext
  def summary
    out = []
    out << "┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓"
    out << "┃         RUN CONTEXT SUMMARY           ┃"
    out << "┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛"
    out << ""
    out << "ID:            #{id}"
    out << "State:         #{state}"
    out << "Pipeline:      #{pipeline&.name} (#{pipeline_id})"
    out << "Source:        #{source}"
    out << "Error:         #{respond_to?(:error_message) ? error_message.presence || 'None' : (error.presence || 'None')}"
    out << "Created At:    #{created_at.strftime('%Y-%m-%d %H:%M:%S')}"
    out << "Last Updated:  #{updated_at.strftime('%Y-%m-%d %H:%M:%S')}"
    out << ""
    out << "── DATA ──────────────────────────────────────────────"

    if data.present?
      data.each do |key, value|
        label = "• #{key}:"
        display = if value.is_a?(Hash)
          value.map { |k, v| "    #{k}: #{v}" }.join("\n")
        elsif value.is_a?(Array)
          JSON.pretty_generate(value).lines.map { |line| "    #{line}" }.join
        else
          "  #{value}"
        end
        out << "#{label}\n#{display}"
      end
    else
      out << "  None"
    end

    out.join("\n")
  end
end

def find_pipelines_targeting(object)
  gid = object.to_gid_param

  matching = DynamicProvisioning::Pipeline
    .includes(:targets)
    .select { |p| p.targets.any? { |t| t.target == gid } }

  if matching.any?
    puts "\n🔗 Pipelines targeting #{object.class.name} #{object.id}:"
    matching.each do |pipeline|
      puts "• #{pipeline.name} (#{pipeline.id})"
    end
    matching
  else
    puts "\n🚫 No pipelines currently target #{object.class.name} #{object.id}."
    []
  end
end

def pipelines_list
  puts "\n📦 Pipelines Summary\n\n"

  DynamicProvisioning::Pipeline
    .includes(:transformations, :targets, :source)
    .order(:name)
    .each do |pipeline|
      id = pipeline.id[0..7] + "..."
      active = pipeline.deleted_at.nil? ? "✅" : "❌"
      target_count = pipeline.targets.size
      updated = begin
        ActionController::Base.helpers.time_ago_in_words(pipeline.updated_at) + " ago"
      rescue
        pipeline.updated_at.strftime("%Y-%m-%d")
      end
      source_type = pipeline.source&.type&.demodulize || "Unknown"

      transformation_summary = pipeline.transformations
        .group_by(&:type)
        .transform_values(&:count)
        .map { |type, count| "#{count} #{type.demodulize.underscore}" }
        .join(", ")

      models = pipeline.transformations
        .select { |t| t.type == "DynamicProvisioning::Transformation::Provisioning" }
        .map { |t| t.data["model"] }
        .uniq
        .presence || ["—"]

      puts "• #{pipeline.name}"
      puts "  ↳ ID: #{id}"
      puts "  ↳ Active: #{active}"
      puts "  ↳ Targets: #{target_count}"
      puts "  ↳ Transformations: #{transformation_summary.presence || '—'}"
      puts "  ↳ Provisioning: #{models.join(', ')}"
      puts "  ↳ Source Type: #{source_type}"
      puts "  ↳ Updated: #{updated}"
      puts ""
    end
end

def pipeline_helper_cheatsheet
  puts   "\n🚀🚀🚀 PIPELINE HELPER — VERSION #{PIPELINE_HELPER_VERSION} 🚀🚀🚀"
  puts "\n📘 Pipeline Helper Cheatsheet:"

  puts "\n📘 Pipeline Instance Methods:"
  puts "• pipeline.summary"
  puts "  → Pretty one-page summary of pipeline configuration, sources, transformations, and targets."

  puts "  → One-liner reminder for how to run the pipeline with RunPipelineJob."

  puts "• pipeline.generate"
  puts "  → Enqueues the pipeline to run via background job."

  puts "• pipeline.target_objects"
  puts "  → Returns an array of resolved target model instances."

  puts "• pipeline.source_object"
  puts "  → Returns the resolved source model instance."

  puts "• pipeline.target_map"
  puts "  → Returns a hash of source objects to target objects (e.g. { Team => DistributionList })."

  puts "\n🔍 Exploration & Listing:"
  puts "• pipelines_list"
  puts "  → Full summary of each pipeline including status, targets, transformations, models, and source type."

  puts "• find_pipelines_targeting(object)"
  puts "  → Given a model instance, return any pipelines that target it."

  puts "\n📥 Usage:"
  puts "• pipeline = DynamicProvisioning::Pipeline.find(\"pipeline-id\")"
  puts "• puts pipeline.summary"
  puts "• puts pipeline.guide"
  puts "• pipeline.generate"

  puts "\n💡 Shortcuts (optional aliases):"
  puts "• dp  = DynamicProvisioning"
  puts "• dpp = DynamicProvisioning::Pipeline"
  puts "• dpt = DynamicProvisioning::Transformation"

  puts "\n🛠️  Source Type Ideas (not yet implemented):"
  puts "• Scope-based: Use existing model scopes"
  puts "• Method Chain: Chain ActiveRecord methods"
  puts "• SQL-based: Direct SQL queries"
  puts "• Association-based: Follow associations from a base record"
  puts "• Currently only SmartQuery sources are supported"
end
pipeline_helper_cheatsheet

# ------------------------------------------------------------------------------
# Backup a DynamicProvisioning pipeline, including its source, transformations, requirements, and targets
# ------------------------------------------------------------------------------
def backup_pipeline(orig_pipeline)
  raise "Pipeline not found" unless orig_pipeline

  # Duplicate the pipeline record
  clone = orig_pipeline.dup
  clone.name = "#{orig_pipeline.name} (Backup #{Time.now.to_i})"
  clone.save!

  # Duplicate the source and associate with the clone
  if orig_pipeline.source
    orig_source = orig_pipeline.source
    new_source = orig_source.dup
    new_source.pipeline = clone
    new_source.save!
  end

  # Duplicate transformations and build mapping of old -> new IDs
  id_mapping = {}
  orig_pipeline.transformations.find_each do |t|
    new_t = t.dup
    new_t.pipeline = clone
    new_t.save!
    id_mapping[t.id] = new_t.id
  end

  # Duplicate requirements, remapping predecessor/successor IDs
  orig_pipeline.requirements.find_each do |req|
    DynamicProvisioning::Requirement.create!(
      pipeline: clone,
      predecessor_id: id_mapping.fetch(req.predecessor_id),
      successor_id:   id_mapping.fetch(req.successor_id)
    )
  end

  # Duplicate targets, remapping transformation IDs and copying record data
  orig_pipeline.targets.find_each do |orig_target|
    DynamicProvisioning::Target.create!(
      pipeline:           clone,
      transformation_id:  id_mapping.fetch(orig_target.transformation_id),
      source_record:      orig_target.source_record,
      target_record:      orig_target.target_record
    )
  end

  clone
end
