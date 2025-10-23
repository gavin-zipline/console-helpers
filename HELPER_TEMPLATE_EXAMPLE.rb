# ------------------------------------------------------------------------------
# Example Helper Template (Team Helper Implementation)
# ------------------------------------------------------------------------------
# Purpose: Demonstrates the standard helper structure and patterns
# NOTE: The first line after comments must be the version constant, e.g. EXAMPLE_HELPER_VERSION = "1.0.0"
# Usage: Load via `gh("team")` or `gh("teams")` then use `team_cheatsheet` for docs
# Flexible access: `team_cheatsheet`, `team_helper_cheatsheet`, `teams_cheatsheet`, etc.
# Safety: Read-only by default, destructive operations require confirmation

EXAMPLE_HELPER_VERSION = "1.0.0"

# --------------------------------- shortcuts -------------------------------- #
def eh_version
  puts "🔧 Example Helper Version: #{EXAMPLE_HELPER_VERSION}"
  EXAMPLE_HELPER_VERSION
end

# ------------------------------------------------------------------------------
# Core Helper Methods - organized by functional category
# ------------------------------------------------------------------------------

# == 🔍 QUERY & SEARCH METHODS ==
# Methods for finding and filtering records

def find_example_record(param)
  # Standard pattern: accept ID, name, or other identifier
  case param
  when Integer
    # In real implementation: Team.find_by(id: param)
    puts "🔍 Would find record by ID: #{param}"
  when String
    # In real implementation: Team.find_by('name ILIKE ?', "%#{param}%")
    puts "🔍 Would find record by name: #{param}"
  else
    raise ArgumentError, "Unsupported param type: #{param.class}"
  end
rescue => e
  puts "❌ Error finding record: #{e.message}"
  nil
end

# == 📊 ANALYSIS & REPORTING METHODS ==
# Methods that generate summaries, statistics, or reports

def example_records_summary
  puts "📊 Example Records Summary:"
  puts "  Total: 1,234"
  puts "  Active: 1,100"
  puts "  Created today: 5"

  # Add domain-specific metrics
  puts "  With special flag: 89"
end

# == 🛠️ UTILITY METHODS ==
# Helper methods for data transformation, formatting, etc.

def format_example_record(record_id = 123)
  <<~INFO
    📋 Example Record Details:
    • ID: #{record_id}
    • Name: Example Record #{record_id}
    • Status: ✅ Active
    • Created: 2025-08-27 14:30
  INFO
rescue => e
  "💥 Error formatting record: #{e.message}"
end

# == 🔧 ADMINISTRATIVE METHODS ==
# Methods for management, maintenance, or advanced operations
# ⚠️ These should include safety confirmations for destructive operations

def safe_example_operation(record_id, confirm: false)
  return "⚠️ This operation requires confirmation. Add confirm: true" unless confirm
  return "❌ Record not found" unless record_id

  # Dry-run: show what would happen
  puts "🔍 Would perform operation on:"
  puts "  • Record ID: #{record_id}"
  puts "  • Record Name: Example Record #{record_id}"

  # In real implementation:
  # result = record.some_operation
  # puts "✅ Operation completed successfully"
  # result

  puts "📝 Dry-run mode - no changes made"
rescue => e
  puts "💥 Error during operation: #{e.message}"
  nil
end

# ------------------------------------------------------------------------------
# Bulk Operations - with built-in safety and progress tracking
# ------------------------------------------------------------------------------

def bulk_example_operation(record_ids = [1, 2, 3], batch_size: 100, confirm: false)
  return "⚠️ This operation requires confirmation. Add confirm: true" unless confirm
  return "❌ No records provided" if record_ids.empty?

  puts "🔄 Processing #{record_ids.size} records in batches of #{batch_size}..."

  record_ids.each_slice(batch_size).with_index do |batch, batch_num|
    puts "  📦 Batch #{batch_num + 1}: Processing #{batch.size} records..."

    batch.each do |record_id|
      begin
        # In real implementation: record.some_operation
        print "."
      rescue => e
        puts "\n💥 Error with record #{record_id}: #{e.message}"
      end
    end

    puts "\n  ✅ Batch #{batch_num + 1} complete"
    sleep(0.1) # Rate limiting for demo
  end

  puts "🎉 Bulk operation completed!"
end

# ------------------------------------------------------------------------------
# Error Handling Utilities
# ------------------------------------------------------------------------------

private

def handle_record_error(error, context = "operation")
  case error
  when ArgumentError
    "❌ Invalid argument: #{error.message}"
  else
    "💥 Unexpected error during #{context}: #{error.class} - #{error.message}"
  end
end

# ------------------------------------------------------------------------------
# Cheatsheet - REQUIRED for all helpers
# ------------------------------------------------------------------------------

def example_helper_cheatsheet
  puts "\n🚀🚀🚀 EXAMPLE HELPER — VERSION #{EXAMPLE_HELPER_VERSION} 🚀🚀🚀"
  puts "\n📘 Example Helper Cheatsheet:"

  puts "\n🔍 Query & Search:"
  puts "• find_example_record(param)     → Find record by ID or name"
  puts "• search_example_records(query)  → Search records by various criteria"

  puts "\n📊 Analysis & Reporting:"
  puts "• example_records_summary        → Overview statistics and counts"
  puts "• analyze_example_usage          → Detailed usage analysis"

  puts "\n🛠️ Utilities:"
  puts "• format_example_record(record)  → Pretty-print record details"
  puts "• validate_example_data(data)    → Check data for issues"

  puts "\n🔧 Administrative:"
  puts "• safe_example_operation(record, confirm: true)  → Safely perform operation"
  puts "• bulk_example_operation(records, confirm: true) → Bulk operation with safety"

  puts "\n💡 Usage Examples:"
  puts "• record = find_example_record('search term')"
  puts "• puts format_example_record(record)"
  puts "• example_records_summary"
  puts "• safe_example_operation(record, confirm: true)"

  puts "\n⚠️ Safety Notes:"
  puts "• All read operations are safe by default"
  puts "• Destructive operations require confirm: true parameter"
  puts "• Bulk operations include progress tracking and rate limiting"
  puts "• Use dry-run mode to preview changes before execution"

  puts "\n📋 Quick Reference:"
  puts "• eh_version                     → Show helper version"
  puts "• example_helper_cheatsheet      → Show this help"
end

# Flexible cheatsheet naming - support multiple conventions for convenience
alias example_cheatsheet example_helper_cheatsheet
alias examples_cheatsheet example_helper_cheatsheet
alias examples_helper_cheatsheet example_helper_cheatsheet

# Auto-display cheatsheet when helper loads
example_helper_cheatsheet

# ------------------------------------------------------------------------------
# Template Customization Guide
# ------------------------------------------------------------------------------
# To create a new helper based on this template:
#
# 1. Copy this file and rename to: your_domain_helper.rb
#
# 2. Replace all "example" references with your domain:
#    - EXAMPLE_HELPER_VERSION → YOUR_DOMAIN_HELPER_VERSION
#    - example_helper_cheatsheet → your_domain_cheatsheet
#    - find_example_record → find_your_model
#    - example_records_summary → your_models_summary
#    - etc.
#
# 3. Implement actual functionality:
#    - Replace puts statements with real database operations
#    - Add domain-specific methods and business logic
#    - Include proper error handling and validation
#
# 4. Test thoroughly:
#    - Verify all methods work in console environment
#    - Test error conditions and edge cases
#    - Confirm safety features prevent accidents
#
# 5. Update documentation:
#    - Customize cheatsheet with actual method names
#    - Add usage examples specific to your domain
#    - Document any special safety considerations
#
# 6. Deploy:
#    - Upload to Gist system
#    - Test loading via gh("your_domain")
#    - Verify cheatsheet discovery works
# ------------------------------------------------------------------------------
