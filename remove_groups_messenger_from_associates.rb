# Script to remove groups.messenger feature flag from Associate Security Level users
# For JIRA ticket INT-285
#
# This script will:
# 1. Identify all Associate SecurityRoles that have groups.messenger enabled
# 2. Identify individual Associate users that have groups.messenger enabled
# 3. Remove the feature flag from these actors
# 4. Provide detailed logging and confirmation

require_relative 'groups_messenger_analysis'

class RemoveGroupsMessengerFromAssociates
  FEATURE_FLAG = 'groups.messenger'.freeze
  ASSOCIATE_ROLE_NAME = 'Associate'.freeze

  def initialize(perform: false, organization_shortname: nil)
    @perform = perform
    @organization_shortname = organization_shortname
    @removed_count = 0
    @error_count = 0
    @log_messages = []
  end

  def call
    log_header

    # Switch to the correct organization if specified
    if @organization_shortname
      log "🏢 Switching to organization: #{@organization_shortname}"
      Apartment::Tenant.switch!(@organization_shortname)
    end

    log "🏢 Current organization: #{Organization.current.name} (#{Organization.current.shortname})"
    log "🎯 Target: Remove '#{FEATURE_FLAG}' from '#{ASSOCIATE_ROLE_NAME}' security level users"
    log "🔧 Perform mode: #{@perform ? 'ENABLED (will make changes)' : 'DISABLED (dry run only)'}"
    log

    # Verify feature flag exists
    unless Features::FeatureFlag.find(FEATURE_FLAG)
      log "❌ ERROR: Feature flag '#{FEATURE_FLAG}' not found in configuration"
      return false
    end

    # Run analysis to understand current state
    log "📊 Running analysis of current state..."
    analysis_result = analyze_groups_messenger_flag

    associate_roles_with_flag = analysis_result[:associate_roles_with_flag]
    individual_associate_users = analysis_result[:individual_associate_users]
    total_affected = analysis_result[:total_affected]

    log
    log "🎯 REMOVAL TARGETS IDENTIFIED:"
    log "   Associate SecurityRoles with flag: #{associate_roles_with_flag.size}"
    log "   Individual Associate users with flag: #{individual_associate_users.size}"
    log "   Total Associate users affected: #{total_affected}"
    log

    if total_affected == 0
      log "✅ No Associate users found with the groups.messenger feature flag. Nothing to remove."
      return true
    end

    # Remove feature flag from Associate SecurityRoles
    if associate_roles_with_flag.any?
      log "🔐 Removing feature flag from Associate SecurityRoles..."
      associate_roles_with_flag.each do |security_role|
        remove_flag_from_actor(security_role)
      end
      log
    end

    # Remove feature flag from individual Associate users
    if individual_associate_users.any?
      log "👤 Removing feature flag from individual Associate users..."
      individual_associate_users.each do |user|
        remove_flag_from_actor(user)
      end
      log
    end

    # Final summary
    log_summary(total_affected)

    true
  end

  private

  def log_header
    log "=" * 80
    log "Remove groups.messenger Feature Flag from Associate Security Level Users"
    log "=" * 80
    log "Script: #{__FILE__}"
    log "Date: #{Time.current.strftime('%Y-%m-%d %H:%M:%S %Z')}"
    log "JIRA Ticket: INT-285"
    log
  end

  def remove_flag_from_actor(actor)
    actor_type = actor.class.name
    actor_name = case actor
                 when SecurityRole
                   "#{actor.name} (Level: #{actor.level})"
                 when User
                   "#{actor.name} (#{actor.email})"
                 else
                   actor.name
                 end

    begin
      # Check if the actor currently has the flag
      unless Flipper.enabled?(FEATURE_FLAG, actor)
        log "  ⚠️  #{actor_type}: #{actor_name} - Feature flag not enabled, skipping"
        return
      end

      if @perform
        # Actually remove the feature flag
        Flipper.disable(FEATURE_FLAG, actor)

        # Verify removal
        if Flipper.enabled?(FEATURE_FLAG, actor)
          log "  ❌ #{actor_type}: #{actor_name} - FAILED TO REMOVE (still enabled after disable)"
          @error_count += 1
        else
          log "  ✅ #{actor_type}: #{actor_name} - Successfully removed feature flag"
          @removed_count += 1
        end
      else
        log "  🔄 #{actor_type}: #{actor_name} - Would remove feature flag (dry run)"
        @removed_count += 1
      end

    rescue => e
      log "  ❌ #{actor_type}: #{actor_name} - ERROR: #{e.message}"
      @error_count += 1
    end
  end

  def log_summary(total_affected)
    log "=" * 80
    log "📋 FINAL SUMMARY"
    log "=" * 80
    log "Organization: #{Organization.current.name} (#{Organization.current.shortname})"
    log "Feature Flag: #{FEATURE_FLAG}"
    log "Target: #{ASSOCIATE_ROLE_NAME} security level users"
    log "Mode: #{@perform ? 'PERFORM (actual changes made)' : 'DRY RUN (no changes made)'}"
    log
    log "Results:"
    log "  🎯 Total Associate users affected: #{total_affected}"
    log "  ✅ Successfully processed: #{@removed_count}"
    log "  ❌ Errors encountered: #{@error_count}"
    log

    if @perform
      if @error_count == 0
        log "🎉 SUCCESS: All Associate users have been successfully removed from the groups.messenger feature flag"
      else
        log "⚠️  PARTIAL SUCCESS: #{@removed_count} processed successfully, #{@error_count} errors occurred"
        log "   Please review the errors above and investigate any failed removals"
      end
    else
      log "ℹ️  DRY RUN COMPLETE: No actual changes were made"
      log "   To execute the removal, run the script again with perform: true"
    end

    log "=" * 80
  end

  def log(message = "")
    puts message
    @log_messages << message
  end
end

# Usage instructions and safety checks
def usage_instructions
  puts <<~USAGE
    =====================================================================
    Remove groups.messenger Feature Flag from Associate Security Level Users
    =====================================================================

    This script removes the groups.messenger feature flag from all users
    at the Associate Security Level as requested in JIRA ticket INT-285.

    USAGE:

    # Dry run (recommended first step):
    RemoveGroupsMessengerFromAssociates.new(perform: false).call

    # Dry run for specific organization:
    RemoveGroupsMessengerFromAssociates.new(perform: false, organization_shortname: 'your-org').call

    # Actual execution (after reviewing dry run):
    RemoveGroupsMessengerFromAssociates.new(perform: true).call

    # Actual execution for specific organization:
    RemoveGroupsMessengerFromAssociates.new(perform: true, organization_shortname: 'your-org').call

    SAFETY FEATURES:
    - Always run with perform: false first to see what would be changed
    - Detailed logging of all actions
    - Verification of removals
    - Error handling and reporting
    - Only targets Associate Security Level users

    =====================================================================
  USAGE
end

# Main execution (when file is run directly)
if __FILE__ == $0
  # Default to dry run for safety
  perform = false
  organization = nil

  puts "Default execution: DRY RUN mode"
  puts "Review the results, then modify the script to set perform: true"
  puts

  # Run the removal
  RemoveGroupsMessengerFromAssociates.new(perform: perform, organization_shortname: organization).call

  puts
  usage_instructions
end
