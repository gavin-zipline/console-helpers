#!/usr/bin/env ruby
# Test script to validate the groups.messenger removal functionality
# For JIRA ticket INT-285

require_relative 'groups_messenger_analysis'
require_relative 'remove_groups_messenger_from_associates'

puts "=" * 80
puts "Testing Groups Messenger Feature Flag Removal for Associate Users"
puts "=" * 80
puts "JIRA Ticket: INT-285"
puts "Date: #{Time.current.strftime('%Y-%m-%d %H:%M:%S %Z')}"
puts
puts "This test will:"
puts "1. Run analysis to understand current state"
puts "2. Run dry-run removal to see what would be changed"
puts "3. Provide instructions for actual execution"
puts
puts "=" * 80
puts

# Step 1: Analysis
puts "STEP 1: ANALYZING CURRENT STATE"
puts "-" * 40
begin
  analyze_groups_messenger_flag
  analysis_success = true
rescue => e
  puts "❌ Analysis failed: #{e.message}"
  puts e.backtrace.first(3)
  analysis_success = false
end

puts
puts "=" * 80
puts

# Step 2: Dry run removal (only if analysis succeeded)
if analysis_success
  puts "STEP 2: DRY RUN REMOVAL"
  puts "-" * 40
  begin
    RemoveGroupsMessengerFromAssociates.new(perform: false).call
    dry_run_success = true
  rescue => e
    puts "❌ Dry run failed: #{e.message}"
    puts e.backtrace.first(3)
    dry_run_success = false
  end
else
  puts "STEP 2: SKIPPED (analysis failed)"
  dry_run_success = false
end

puts
puts "=" * 80
puts

# Step 3: Instructions
puts "STEP 3: EXECUTION INSTRUCTIONS"
puts "-" * 40

if analysis_success && dry_run_success
  puts "✅ Test completed successfully!"
  puts
  puts "Next steps to actually remove the feature flag:"
  puts
  puts "1. Review the dry run results above"
  puts "2. If the results look correct, execute the actual removal:"
  puts
  puts "   # In Rails console:"
  puts "   load 'console-helpers/remove_groups_messenger_from_associates.rb'"
  puts "   RemoveGroupsMessengerFromAssociates.new(perform: true).call"
  puts
  puts "3. Or run this script as a customer script:"
  puts "   # Copy the removal script to customer_scripts/"
  puts "   # Run with appropriate organization context"
  puts
  puts "IMPORTANT SAFETY NOTES:"
  puts "- Always run dry run first (perform: false)"
  puts "- Verify the organization context is correct"
  puts "- Only affects Associate Security Level users"
  puts "- Provides detailed logging and verification"
else
  puts "❌ Test failed - please review errors above"
  puts
  puts "Common issues:"
  puts "- Feature flag might not exist in current organization"
  puts "- Database connection issues"
  puts "- Missing required classes or modules"
  puts
  puts "Please fix the issues and run the test again"
end

puts
puts "=" * 80
puts "Test complete"
puts "=" * 80
