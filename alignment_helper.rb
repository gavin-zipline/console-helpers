# frozen_string_literal: true

# === ALIGNMENT CONSOLE HELPER ===
# A helper for investigating and running automated alignments
# Supports both team and user alignment classes and actions.

require 'csv'

ALIGNMENT_HELPER_VERSION = '0.1.0'
HELPER_VERSION = ALIGNMENT_HELPER_VERSION

def team_file(org)
  "Alignment::TeamFile::#{org}".constantize
end

def user_alignment(org)
  "Alignment::UserAlignment::#{org}".constantize
end

def run_latest_team_file(org)
  team_file(org).process_latest
end

def show_raw_data(org)
  raw_file = team_file(org).order(:created_at).last&.send(:raw_file)
  return nil unless raw_file

  CSV.read(raw_file.download, headers: true, col_sep: "\t")
end

def pending_terminations
  Alignment::UserAlignment::ImplicitTermination.where(state: :pending)
end

def alignment_cheatsheet
  puts "\n🚀 ALIGNMENT HELPER — VERSION #{ALIGNMENT_HELPER_VERSION}"
  puts "\n📘 Commands:"
  puts "team_file(<org>)                # => Alignment::TeamFile::<Org>"
  puts "user_alignment(<org>)           # => Alignment::UserAlignment::<Org>"
  puts "run_latest_team_file(<org>)     # => Run .process_latest"
  puts "show_raw_data(<org>)            # => Show latest file CSV"
  puts "pending_terminations            # => Show pending user terminations"
  puts "yank_alignment_data(<org>)         # => Show rake command to pull prod alignment data locally"
  puts "latest_user_alignment           # => Most recent Alignment::UserFile::<Org> instance"
  puts "latest_team_alignment           # => Most recent Alignment::TeamFile::<Org> instance"
  puts "latest_user_alignment.summary   # => Status counts and % changes/errors"
  puts "latest_user_alignment.errors    # => Hash of error_class => [rows]"
  puts "latest_user_alignment.errors_summary # => Summary string of error counts"
  puts "latest_team_alignment.summary   # => Status counts and % changes/errors"
  puts "latest_team_alignment.errors    # => Hash of error_class => [rows]"
  puts "latest_team_alignment.errors_summary # => Summary string of error counts"
end

alignment_cheatsheet

# --- Latest alignment file helpers ---
def latest_user_alignment
  tenant = Organization.current.shortname.capitalize
  klass = "Alignment::UserFile::#{tenant}".safe_constantize
  return unless klass

  klass.order(created_at: :desc).first
end

def latest_team_alignment
  tenant = Organization.current.shortname.capitalize
  klass = "Alignment::TeamFile::#{tenant}".safe_constantize
  return unless klass

  klass.order(created_at: :desc).first
end
