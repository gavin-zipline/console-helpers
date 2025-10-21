# frozen_string_literal: true

# ------------------------------------------------------------------------------
# Alignment Helper
# ------------------------------------------------------------------------------
# Purpose: Helper for investigating and running automated alignments.
#          Supports both team and user alignment classes and actions.
# Usage: Load via `gh("alignment")` then use `alignment_cheatsheet` for docs
# Safety: Read-only operations for data inspection. Process operations should be used carefully.

require 'csv'

# == Alignment Helper Version and Registration ==
ALIGNMENT_HELPER_VERSION = "0.2.0"

# --------------------------------- shortcuts -------------------------------- #
# Convenient shortcuts for common alignment operations

def ta(org = nil)
  org ||= Organization.current.shortname.capitalize
  team_file(org)
end

def ua(org = nil)
  org ||= Organization.current.shortname.capitalize
  user_alignment(org)
end

# Registration and cheatsheet method must be at the top for convention compliance
def alignment_cheatsheet
  puts "\n🚀🚀🚀 ALIGNMENT HELPER — VERSION #{ALIGNMENT_HELPER_VERSION} 🚀🚀🚀"
  puts "\n📘 Alignment Helper Cheatsheet:"
  puts "\n🔍 QUERY & SEARCH METHODS:"
  puts "• team_file(org)                     → Get Alignment::TeamFile::<Org> class"
  puts "• user_alignment(org)                → Get Alignment::UserAlignment::<Org> class"
  puts "• ta(org=current)                    → Shortcut for team_file"
  puts "• ua(org=current)                    → Shortcut for user_alignment"
  puts "• latest_user_alignment              → Most recent Alignment::UserFile::<Org> instance"
  puts "• latest_team_alignment              → Most recent Alignment::TeamFile::<Org> instance"
  puts "• pending_terminations               → Show pending user terminations"
  puts "\n📊 ANALYSIS & REPORTING METHODS:"
  puts "• show_raw_data(org)                 → Show latest alignment file CSV data"
  puts "• latest_user_alignment.summary      → Status counts and % changes/errors"
  puts "• latest_user_alignment.errors       → Hash of error_class => [rows]"
  puts "• latest_user_alignment.errors_summary → Summary string of error counts"
  puts "• latest_team_alignment.summary      → Status counts and % changes/errors"
  puts "• latest_team_alignment.errors       → Hash of error_class => [rows]"
  puts "• latest_team_alignment.errors_summary → Summary string of error counts"
  puts "• error_tally(alignment=latest_user)  → Count errors by type"
  puts "• non_team_errors(alignment=latest_user) → Errors excluding team not found"
  puts "• team_key_errors(alignment=latest_user) → Just team integration_key errors"
  puts "\n🛠️ UTILITY METHODS:"
  puts "• yank_alignment_data(org)           → Show rake command to pull prod alignment data locally"
  puts "\n🔧 ADMINISTRATIVE METHODS:"
  puts "• run_latest_team_file(org)          → ⚠️  Run .process_latest (processes alignment)"
  puts "\n💡 Usage Examples:"
  puts "  ta('Pacsun').count                  # Get TeamFile class count"
  puts "  latest_user_alignment.summary       # Show alignment summary"
  puts "  error_tally                         # Count all errors by type"
  puts "  non_team_errors.count               # Count non-team errors"
  puts "  team_key_errors.count               # Count team integration key errors"
  puts "  show_raw_data('Nike')               # View raw CSV data"
end

ConsoleHelpers.register_helper("alignment", ALIGNMENT_HELPER_VERSION, method(:alignment_cheatsheet))

# ------------------------------------------------------------------------------
# Core Helper Methods - organized by functional category
# ------------------------------------------------------------------------------

# == 🔍 QUERY & SEARCH METHODS ==
# Methods for finding and filtering alignment records

def team_file(org)
  "Alignment::TeamFile::#{org}".constantize
rescue => e
  puts "❌ Error finding team file class for #{org}: #{e.message}"
  nil
end

def user_alignment(org)
  "Alignment::UserAlignment::#{org}".constantize
rescue => e
  puts "❌ Error finding user alignment class for #{org}: #{e.message}"
  nil
end

def pending_terminations
  Alignment::UserAlignment::ImplicitTermination.where(state: :pending)
rescue => e
  puts "❌ Error finding pending terminations: #{e.message}"
  nil
end

# == 📊 ANALYSIS & REPORTING METHODS ==
# Methods that generate summaries, statistics, or reports

def show_raw_data(org)
  raw_file = team_file(org).order(:created_at).last&.send(:raw_file)
  return nil unless raw_file

  CSV.read(raw_file.download, headers: true, col_sep: "\t")
rescue => e
  puts "❌ Error reading raw data for #{org}: #{e.message}"
  nil
end

def error_tally(alignment = nil)
  alignment ||= latest_user_alignment
  return nil unless alignment

  alignment.alignments.where.not(error: nil).pluck(:error).tally
rescue => e
  puts "❌ Error getting error tally: #{e.message}"
  nil
end

def non_team_errors(alignment = nil)
  alignment ||= latest_user_alignment
  return nil unless alignment

  team_error = "Couldn't find Team with [WHERE \"teams\".\"deleted_at\" IS NULL AND \"teams\".\"integration_key\" = $1]"
  alignment.alignments.where.not(error: team_error).where.not(error: nil)
rescue => e
  puts "❌ Error getting non-team errors: #{e.message}"
  nil
end

def team_key_errors(alignment = nil)
  alignment ||= latest_user_alignment
  return nil unless alignment

  team_error = "Couldn't find Team with [WHERE \"teams\".\"deleted_at\" IS NULL AND \"teams\".\"integration_key\" = $1]"
  alignment.alignments.where(error: team_error)
rescue => e
  puts "❌ Error getting team key errors: #{e.message}"
  nil
end

# == 🛠️ UTILITY METHODS ==
# Helper methods for data transformation, formatting, etc.

def yank_alignment_data(org)
  puts "📋 To pull production alignment data locally for #{org}:"
  puts "  rake alignment:pull_prod_data[#{org}]"
  puts ""
  puts "💡 This will download the latest alignment files from production"
rescue => e
  puts "❌ Error generating yank command: #{e.message}"
end

# == 🔧 ADMINISTRATIVE METHODS ==
# Methods for management, maintenance, or advanced operations
# ⚠️ These should include safety confirmations for destructive operations

def run_latest_team_file(org, confirm: false)
  return "⚠️ This operation processes alignment data and may make changes. Add confirm: true" unless confirm

  puts "🔍 Processing latest team file for #{org}..."
  result = team_file(org).process_latest
  puts "✅ Processing completed successfully"
  result
rescue => e
  puts "💥 Error processing team file for #{org}: #{e.message}"
  nil
end

# --- Latest alignment file helpers ---
def latest_user_alignment(org = nil)
  tenant = org || Organization.current.shortname.capitalize
  klass = "Alignment::UserFile::#{tenant}".safe_constantize
  return nil unless klass

  klass.order(created_at: :desc).first
rescue => e
  puts "❌ Error finding latest user alignment for #{tenant}: #{e.message}"
  nil
end

def latest_team_alignment(org = nil)
  tenant = org || Organization.current.shortname.capitalize
  klass = "Alignment::TeamFile::#{tenant}".safe_constantize
  return nil unless klass

  klass.order(created_at: :desc).first
rescue => e
  puts "❌ Error finding latest team alignment for #{tenant}: #{e.message}"
  nil
end

# Call cheatsheet on load for auto-display
alignment_cheatsheet
