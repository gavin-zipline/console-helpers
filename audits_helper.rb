AUDITS_HELPER_VERSION = "0.1.0"
def audits_helper_cheatsheet
  puts "\n📘 Audits Helper Cheatsheet:"
  puts "• Add your audits helper methods here."
end
ConsoleHelpers.register_helper("audits", AUDITS_HELPER_VERSION, method(:audits_helper_cheatsheet))
# Audits Console Helper for Zipline

def audits_helper_version
  puts "🧭 Audits Helper Version: #{AUDITS_HELPER_VERSION}"
end

# === Auditing Utilities ===

def audits_without_preferences
  audits.reject do |audit|
    audit.audited_changes.key?("preferences")
  end
end

# === Array Extensions ===
class Array
  def chrono
    return unless all? { |element| element.is_a?(Audited::Audit) }

    sort_by(&:created_at).each do |audit|
      changes_description = audit.audited_changes.map do |attribute, values|
        old_value, new_value = values
        "#{attribute} was changed from #{old_value.nil? ? 'nil' : old_value.inspect} to #{new_value.inspect}"
      end.join(' and ')

      created_at_local = audit.created_at.getlocal('-08:00') # PST
      created_at_formatted = created_at_local.strftime("%A, %b %d, %Y at %I:%M %p %Z")

      puts "- On #{created_at_formatted}, #{changes_description}."
    end
  end
end

# === Audit Summary Formatter ===

def audit_summaries(audits)
  audits.map do |audit|
    changes = audit.audited_changes.deep_dup

    # Summarize distribution changes
    if changes["distribution"]
      changes["distribution"] = changes["distribution"].map do |dist|
        dist.map do |d|
          if d.is_a?(Hash) && d["teams"]
            total_teams = d["teams"].size
            d["teams"] = ["... (#{total_teams} teams)"]
          end
          d
        end
      end
    end

    {
      at: audit.created_at.strftime("%Y-%m-%d %H:%M"),
      changes: changes
    }
  end
end

def audits_cheatsheet
  puts   "\n🚀🚀🚀 AUDITS HELPER — VERSION #{AUDITS_HELPER_VERSION} 🚀🚀🚀"
  puts "\n📘 Audits Helper Cheatsheet:"
  puts "\n🛠 Methods:"
  puts "• audits_without_preferences → Filters out audits where only preferences changed"
  puts "• Array#chrono               → Prints a chronological summary of audit changes"
  puts "• audit_summaries(audits)   → Summary of audit changes with truncated distribution info"
end
audits_cheatsheet
