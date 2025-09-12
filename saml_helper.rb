SAML_HELPER_VERSION = "0.1.0"
def saml_helper_cheatsheet
  puts "\n📘 SAML Helper Cheatsheet:"
  puts "• Add your SAML helper methods here."
end
ConsoleHelpers.register_helper("saml", SAML_HELPER_VERSION, method(:saml_helper_cheatsheet))
# Version constant
SAML_HELPER_VERSION = "0.1.0"
# ---------------------------------------------------------------------------- #
#                                  saml_helper                                 #
# ---------------------------------------------------------------------------- #

# Search for failed SAML events by a string like an email or employee number.
# This method looks for events with "saml:debug:handler:event" in the activity field
# and checks if the provided string exists in the details field.
#
# Usage:
#   search_saml_debug_events("Lamar.Harrison@riteaid.com")
#   search_saml_debug_events("2011802")
def search_saml_debug_events(search_string)
  target_activity = "saml:debug:handler:event"

  # Optimize query: Scope first, filter, and sort in the database
  matching_events = EventStream::Event.where(activity: target_activity)
                                      .where("details::text ILIKE ?", "%#{search_string}%")
                                      .order(:created_at) # Ensure ascending order

  # Display results in a cleaner format
  if matching_events.any?
    puts "\n=== Found #{matching_events.size} matching SAML debug events ==="
    matching_events.each do |event|
      puts "ID: #{event.id} | Created At: #{event.created_at.strftime('%Y-%m-%d %H:%M:%S %Z')}"
      puts "Details: #{event.details.is_a?(Hash) ? event.details.to_json : event.details}"
      puts "------------------------------------------------------------"
    end
  else
    puts "No matching SAML debug events found for '#{search_string}'."
  end

  matching_events # Return results
end

# Search for all SAML events associated with a specific user ID.
#
# Usage:
#   search_saml_events_by_user(128454)
def search_saml_events_by_user(user_id)
  target_activity = "saml:debug:handler:event"

  matching_events = EventStream::Event.where(activity: target_activity, user_id: user_id)
                                      .order(:created_at)

  if matching_events.any?
    puts "\n=== Found #{matching_events.size} SAML events for User ID: #{user_id} ==="
    matching_events.each do |event|
      puts "ID: #{event.id} | Created At: #{event.created_at.strftime('%Y-%m-%d %H:%M:%S %Z')}"
      puts "Details: #{event.details.is_a?(Hash) ? event.details.to_json : event.details}"
      puts "------------------------------------------------------------"
    end
  else
    puts "No SAML events found for User ID: #{user_id}."
  end

  matching_events
end

# Retrieve the latest failed SAML authentication event.
# This searches for events with "saml:debug:handler:event" that contain "error" in the details.
#
# Usage:
#   latest_failed_saml_event
def latest_failed_saml_event
  event = EventStream::Event.where(activity: "saml:debug:handler:event")
                            .where("details::text ILIKE ?", "%error%")
                            .order(created_at: :desc)
                            .first

  if event
    puts "\n=== Latest Failed SAML Event ==="
    puts "ID: #{event.id} | Created At: #{event.created_at.strftime('%Y-%m-%d %H:%M:%S %Z')}"
    puts "Details: #{event.details.is_a?(Hash) ? event.details.to_json : event.details}"
  else
    puts "No failed SAML events found."
  end

  event
end

# Retrieve the raw SAML request and response for a specific user ID.
# This helps debug authentication issues by fetching the most recent raw request and response.
#
# Usage:
#   get_saml_request_response(128454)
def get_saml_request_response(user_id)
  request_event = EventStream::Event.where(activity: "saml:debug:controller:raw_request", user_id: user_id)
                                    .order(created_at: :desc)
                                    .first

  response_event = EventStream::Event.where(activity: "saml:debug:controller:raw_response", user_id: user_id)
                                     .order(created_at: :desc)
                                     .first

  puts "\n=== SAML Request ==="
  if request_event
    puts "ID: #{request_event.id} | Created At: #{request_event.created_at}"
    puts "Details: #{request_event.details.is_a?(Hash) ? request_event.details.to_json : request_event.details}"
  else
    puts "No SAML request found."
  end

  puts "\n=== SAML Response ==="
  if response_event
    puts "ID: #{response_event.id} | Created At: #{response_event.created_at}"
    puts "Details: #{response_event.details.is_a?(Hash) ? response_event.details.to_json : response_event.details}"
  else
    puts "No SAML response found."
  end
end

# Check if a user had a successful SAML login.
# Searches for the latest "saml:debug:handler:event" entry with "success" in the details.
#
# Usage:
#   user_saml_login_successful?(128454)
def user_saml_login_successful?(user_id)
  success_event = EventStream::Event.where(activity: "saml:debug:handler:event", user_id: user_id)
                                    .where("details::text ILIKE ?", "%success%")
                                    .order(created_at: :desc)
                                    .first

  if success_event
    puts "✅ User ID #{user_id} had a successful SAML login at #{success_event.created_at}."
    true
  else
    puts "❌ No successful SAML login found for User ID #{user_id}."
    false
  end
end

# ---------------------------------------------------------------------------- #
#                               Cheatsheet Method                              #
# ---------------------------------------------------------------------------- #

def saml_helper_cheatsheet
  puts   "\n🚀🚀🚀 SAML HELPER — VERSION #{SAML_HELPER_VERSION} 🚀🚀🚀"
  puts "\n📘 SAML Helper Cheatsheet:"
  puts "\n🛠 Methods:"
  puts "• search_saml_debug_events(string)     → Search failed SAML events by email or employee number"
  puts "• search_saml_events_by_user(user_id)  → All SAML debug events for a user"
  puts "• latest_failed_saml_event             → Most recent failed SAML login event"
  puts "• get_saml_request_response(user_id)   → Raw SAML request/response for user"
  puts "• user_saml_login_successful?(user_id) → Check if a user successfully authenticated"
end

saml_helper_cheatsheet
