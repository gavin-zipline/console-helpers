# ------------------------------------------------------------------------------
# [HELPER_NAME] Helper Template
# ------------------------------------------------------------------------------
# Purpose: [Brief description of what this helper does]
# NOTE: The first line after comments must be the version constant, e.g. [HELPER_NAME]_HELPER_VERSION = "1.0.0"
# Usage: Load via `gh("[helper_name]")` or `gh("[helper_names]")` then use `[helper_name]_cheatsheet` for docs
# Flexible access: `[helper_name]_cheatsheet`, `[helper_name]_helper_cheatsheet`, `[helper_names]_cheatsheet`, etc.
# Safety: [Describe safety features - read-only, confirmation required, etc.]


# == [HELPER_NAME] Helper Version and Registration ==
[HELPER_NAME]_HELPER_VERSION = "1.0.0"

# --------------------------------- shortcuts -------------------------------- #
# Optional: Add convenient shortcuts for common operations
# Example: def find_x(param); end


# Registration and cheatsheet method must be at the top for convention compliance
def [helper_name]_cheatsheet
  puts "\n�🚀🚀 [HELPER_NAME] HELPER — VERSION #{[HELPER_NAME]_HELPER_VERSION} 🚀🚀🚀"
  puts "\n📘 [Helper Name] Helper Cheatsheet:"
  # ...
end

# Flexible cheatsheet naming - support multiple conventions for convenience
alias [helper_name]_helper_cheatsheet [helper_name]_cheatsheet
alias [helper_names]_cheatsheet [helper_name]_cheatsheet
alias [helper_names]_helper_cheatsheet [helper_name]_cheatsheet

ConsoleHelpers.register_helper("[helper_name]", [HELPER_NAME]_HELPER_VERSION, method(:[helper_name]_cheatsheet))

# ------------------------------------------------------------------------------
# Core Helper Methods - organized by functional category
# ------------------------------------------------------------------------------

# == 🔍 QUERY & SEARCH METHODS ==
# Methods for finding and filtering records

def find_[model](param)
  # Standard pattern: accept ID, name, or other identifier
  case param
  when Integer
    [Model].find_by(id: param)
  when String
    [Model].find_by('[searchable_field] ILIKE ?', "%#{param}%")
  else
    raise ArgumentError, "Unsupported param type: #{param.class}"
  end
rescue => e
  puts "❌ Error finding [model]: #{e.message}"
  nil
end

# == 📊 ANALYSIS & REPORTING METHODS ==
# Methods that generate summaries, statistics, or reports

def [models]_summary
  puts "📊 [Models] Summary:"
  puts "  Total: #{[Model].count}"
  puts "  Active: #{[Model].where(active: true).count}"
  puts "  Created today: #{[Model].where('created_at >= ?', Date.current).count}"

  # Add domain-specific metrics
  # puts "  [Specific metric]: #{[Model].[specific_scope].count}"
end

# == 🛠️ UTILITY METHODS ==
# Helper methods for data transformation, formatting, etc.

def format_[model]([model])
  return "❌ [Model] not found" unless [model]

  <<~INFO
    📋 [Model] Details:
    • ID: #{[model].id}
    • Name: #{[model].name}
    • Status: #{[model].active? ? '✅ Active' : '❌ Inactive'}
    • Created: #{[model].created_at.strftime('%Y-%m-%d %H:%M')}
  INFO
rescue => e
  "💥 Error formatting [model]: #{e.message}"
end

# == 🔧 ADMINISTRATIVE METHODS ==
# Methods for management, maintenance, or advanced operations
# ⚠️ These should include safety confirmations for destructive operations

def safe_[operation]([model], confirm: false)
  return "⚠️ This operation requires confirmation. Add confirm: true" unless confirm
  return "❌ [Model] not found" unless [model]

  # Dry-run: show what would happen
  puts "🔍 Would perform [operation] on:"
  puts "  • [Model] ID: #{[model].id}"
  puts "  • [Model] Name: #{[model].name}"

  # Uncomment for actual implementation:
  # result = [model].[operation]
  # puts "✅ [Operation] completed successfully"
  # result

  puts "📝 Dry-run mode - no changes made"
rescue => e
  puts "💥 Error during [operation]: #{e.message}"
  nil
end

# ------------------------------------------------------------------------------
# Bulk Operations - with built-in safety and progress tracking
# ------------------------------------------------------------------------------

def bulk_[operation]([models], batch_size: 100, confirm: false)
  return "⚠️ This operation requires confirmation. Add confirm: true" unless confirm
  return "❌ No [models] provided" if [models].empty?

  puts "🔄 Processing #{[models].size} [models] in batches of #{batch_size}..."

  [models].each_slice(batch_size).with_index do |batch, batch_num|
    puts "  📦 Batch #{batch_num + 1}: Processing #{batch.size} [models]..."

    batch.each do |[model]|
      begin
        # Perform operation
        # result = [model].[operation]
        print "."
      rescue => e
        puts "\n💥 Error with [model] #{[model].id}: #{e.message}"
      end
    end

    puts "\n  ✅ Batch #{batch_num + 1} complete"
    sleep(0.5) # Rate limiting
  end

  puts "🎉 Bulk [operation] completed!"
end

# ------------------------------------------------------------------------------
# Error Handling Utilities
# ------------------------------------------------------------------------------

private

def handle_[model]_error(error, context = "operation")
  case error
  when ActiveRecord::RecordNotFound
    "❌ [Model] not found"
  when ActiveRecord::RecordInvalid
    "❌ [Model] validation failed: #{error.record.errors.full_messages.join(', ')}"
  when ArgumentError
    "❌ Invalid argument: #{error.message}"
  else
    "💥 Unexpected error during #{context}: #{error.class} - #{error.message}"
  end
end

# ------------------------------------------------------------------------------
# Cheatsheet - REQUIRED for all helpers
# ------------------------------------------------------------------------------

def [helper_name]_cheatsheet
  puts "\n🚀🚀🚀 [HELPER_NAME] HELPER — VERSION #{[HELPER_NAME]_HELPER_VERSION} 🚀🚀🚀"
  puts "\n📘 [Helper Name] Helper Cheatsheet:"

  puts "\n🔍 Query & Search:"
  puts "• find_[model](param)           → Find [model] by ID or name"
  puts "• [models]_by_[criteria](value) → Find [models] matching criteria"

  puts "\n📊 Analysis & Reporting:"
  puts "• [models]_summary              → Overview statistics and counts"
  puts "• analyze_[models]([scope])     → Detailed analysis of [models]"

  puts "\n🛠️ Utilities:"
  puts "• format_[model]([model])       → Pretty-print [model] details"
  puts "• validate_[model]([model])     → Check [model] for issues"

  puts "\n🔧 Administrative:"
  puts "• safe_[operation]([model], confirm: true)  → Safely perform [operation]"
  puts "• bulk_[operation]([models], confirm: true) → Bulk [operation] with safety"

  puts "\n💡 Usage Examples:"
  puts "• [model] = find_[model]('search term')"
  puts "• puts format_[model]([model])"
  puts "• [models]_summary"
  puts "• safe_[operation]([model], confirm: true)"

  puts "\n⚠️ Safety Notes:"
  puts "• All read operations are safe by default"
  puts "• Destructive operations require confirm: true parameter"
  puts "• Bulk operations include progress tracking and rate limiting"
  puts "• Use dry-run mode to preview changes before execution"

  puts "\n📋 Quick Reference:"
  puts "• [helper_name]_helper_version  → Show helper version"
  puts "• [helper_name]_cheatsheet      → Show this help"
end


# Auto-display cheatsheet when helper loads
[helper_name]_cheatsheet

# ------------------------------------------------------------------------------
# Template Usage Instructions
# ------------------------------------------------------------------------------
# 1. Replace all [PLACEHOLDER] values with actual names:
#    - [HELPER_NAME] → TEAM (all caps for constants)
#    - [helper_name] → team (lowercase for methods)
#    - [helper_names] → teams (lowercase plural for flexible access)
#    - [Helper Name] → Team (title case for display)
#    - [model] → team (lowercase singular)
#    - [models] → teams (lowercase plural)
#    - [Model] → Team (class name)
#    - [operation] → specific operation name
#    - [criteria] → search criteria
#
# 2. Implement actual functionality:
#    - Replace placeholder logic with real implementation
#    - Add domain-specific methods and features
#    - Include proper error handling and validation
#
# 3. Test thoroughly:
#    - Verify all methods work in console environment
#    - Test error conditions and edge cases
#    - Confirm safety features prevent accidents
#
# 4. Update documentation:
#    - Customize cheatsheet with actual method names
#    - Add usage examples specific to your domain
#    - Document any special safety considerations
#
# 5. Deploy:
#    - Upload to GitHub repo (raw file access)
#    - Test loading via gh("helper_name") and gh("helper_names")
#    - Test flexible cheatsheet access: helper_name_cheatsheet, helper_names_cheatsheet
#    - Verify cheatsheet discovery works
# ------------------------------------------------------------------------------
