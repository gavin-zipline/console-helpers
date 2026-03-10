# frozen_string_literal: true

# rubocop:disable I18n/GetText/DecorateString, I18n/RailsI18n/DecorateString

SAML_HELPER_VERSION = '0.2.0'
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
# rubocop:disable Metrics/AbcSize, Metrics/MethodLength
# :reek:TooManyStatements
def search_saml_debug_events(search_string)
  target_activity = 'saml:debug:handler:event'

  # Optimize query: Scope first, filter, and sort in the database
  matching_events = EventStream::Event.where(activity: target_activity)
                                      .where('details::text ILIKE ?', "%#{search_string}%")
                                      .order(:created_at) # Ensure ascending order

  # Display results in a cleaner format
  if matching_events.any?
    puts "\n=== Found #{matching_events.size} matching SAML debug events ==="
    matching_events.each do |event|
      details = event.details
      puts "ID: #{event.id} | Created At: #{event.created_at.strftime('%Y-%m-%d %H:%M:%S %Z')}"
      puts "Details: #{details.is_a?(Hash) ? details.to_json : details}"
      puts '------------------------------------------------------------'
    end
  else
    puts "No matching SAML debug events found for '#{search_string}'."
  end

  matching_events # Return results
end
# rubocop:enable Metrics/AbcSize, Metrics/MethodLength

# Search for all SAML events associated with a specific user ID.
#
# Usage:
#   search_saml_events_by_user(128454)
# rubocop:disable Metrics/MethodLength
# :reek:TooManyStatements
def search_saml_events_by_user(user_id)
  target_activity = 'saml:debug:handler:event'

  matching_events = EventStream::Event.where(activity: target_activity, user_id: user_id)
                                      .order(:created_at)

  if matching_events.any?
    puts "\n=== Found #{matching_events.size} SAML events for User ID: #{user_id} ==="
    matching_events.each do |event|
      details = event.details
      puts "ID: #{event.id} | Created At: #{event.created_at.strftime('%Y-%m-%d %H:%M:%S %Z')}"
      puts "Details: #{details.is_a?(Hash) ? details.to_json : details}"
      puts '------------------------------------------------------------'
    end
  else
    puts "No SAML events found for User ID: #{user_id}."
  end

  matching_events
end
# rubocop:enable Metrics/MethodLength

# Retrieve the latest failed SAML authentication event.
# This searches for events with "saml:debug:handler:event" that contain "error" in the details.
#
# Usage:
#   latest_failed_saml_event
# rubocop:disable Metrics/MethodLength
# :reek:FeatureEnvy
def latest_failed_saml_event
  event = EventStream::Event.where(activity: 'saml:debug:handler:event')
                            .where('details::text ILIKE ?', '%error%')
                            .order(created_at: :desc)
                            .first

  if event
    details = event.details
    puts "\n=== Latest Failed SAML Event ==="
    puts "ID: #{event.id} | Created At: #{event.created_at.strftime('%Y-%m-%d %H:%M:%S %Z')}"
    puts "Details: #{details.is_a?(Hash) ? details.to_json : details}"
  else
    puts 'No failed SAML events found.'
  end

  event
end
# rubocop:enable Metrics/MethodLength

# Retrieve the raw SAML request and response for a specific user ID.
# This helps debug authentication issues by fetching the most recent raw request and response.
#
# Usage:
#   get_saml_request_response(128454)
# rubocop:disable Metrics/AbcSize, Metrics/MethodLength
# :reek:TooManyStatements
def get_saml_request_response(user_id)
  request_event = EventStream::Event.where(activity: 'saml:debug:controller:raw_request', user_id: user_id)
                                    .order(created_at: :desc)
                                    .first

  response_event = EventStream::Event.where(activity: 'saml:debug:controller:raw_response', user_id: user_id)
                                     .order(created_at: :desc)
                                     .first

  puts "\n=== SAML Request ==="
  if request_event
    req_details = request_event.details
    puts "ID: #{request_event.id} | Created At: #{request_event.created_at}"
    puts "Details: #{req_details.is_a?(Hash) ? req_details.to_json : req_details}"
  else
    puts 'No SAML request found.'
  end

  puts "\n=== SAML Response ==="
  if response_event
    res_details = response_event.details
    puts "ID: #{response_event.id} | Created At: #{response_event.created_at}"
    puts "Details: #{res_details.is_a?(Hash) ? res_details.to_json : res_details}"
  else
    puts 'No SAML response found.'
  end
end
# rubocop:enable Metrics/AbcSize, Metrics/MethodLength

# Check if a user had a successful SAML login.
# Searches for the latest "saml:debug:handler:event" entry with "success" in the details.
#
# Usage:
#   user_saml_login_successful?(128454)
# rubocop:disable Metrics/MethodLength
def user_saml_login_successful?(user_id)
  success_event = EventStream::Event.where(activity: 'saml:debug:handler:event', user_id: user_id)
                                    .where('details::text ILIKE ?', '%success%')
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
# rubocop:enable Metrics/MethodLength

# Show a quick-status summary of the primary SAML configuration.
# Run this at the start of any SAML cert rotation or SSO troubleshooting ticket
# to establish whether the org is in Scenario A (metadata URL set -- auto-refresh)
# or Scenario B (static cert only -- manual update required).
#
# Usage:
#   saml_config_summary
# rubocop:disable Metrics/AbcSize, Metrics/MethodLength
# :reek:TooManyStatements
def saml_config_summary
  config = Saml::Configuration.primary
  puts "\n=== SAML Config Summary ==="
  puts "Enabled:            #{config.enabled?}"
  puts "Debug mode:         #{config.debug_mode?}"
  puts "Setup mode:         #{config.setup_mode?}"
  puts "Logout enabled:     #{config.logout_enabled?}"
  puts "Handler:            #{config.handler.presence || '(none)'}"
  puts "IdP metadata URL:   #{config.idp_metadata_url.presence || '(not set -- Scenario B: static cert only)'}"
  puts "IdP metadata (XML): #{config.idp_metadata.present? ? 'populated' : '(empty)'}"
  puts "Signing cert(s):    #{config.settings.idp_cert_multi[:signing]&.count || 0} loaded"
  config
end
# rubocop:enable Metrics/AbcSize, Metrics/MethodLength

# Compare the currently stored SAML signing/encryption certs against those
# available at a new IdP metadata URL. Use this during cert rotation triage to
# determine whether a maintenance window is needed:
#   same      -> safe to add the metadata URL now; auto-refresh handles the rotation
#   different -> coordinate a manual swap during an agreed maintenance window
#
# Usage:
#   compare_saml_certs("https://login.microsoftonline.com/{tenant-id}/federationmetadata/2007-06/federationmetadata.xml?appid={app-id}")
# rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity
# :reek:TooManyStatements
def compare_saml_certs(new_metadata_url)
  current_idp_certs = Saml::Configuration.primary.settings.idp_cert_multi
  parser = OneLogin::RubySaml::IdpMetadataParser.new
  new_idp_certs = parser.parse(parser.send(:get_idp_metadata, new_metadata_url, true)).idp_cert_multi

  same_signing = (current_idp_certs[:signing] & new_idp_certs[:signing]).any?
  same_encryption = if current_idp_certs[:encryption]&.any?
                      (current_idp_certs[:encryption] & new_idp_certs[:encryption]).any?
                    else
                      true # No encryption cert required -- treat as matching
                    end

  puts "\n=== SAML Cert Comparison ==="
  puts "Current signing certs:  #{current_idp_certs[:signing]&.count || 0}"
  puts "Metadata signing certs: #{new_idp_certs[:signing]&.count || 0}"
  puts "Signing match:          #{same_signing ? '✅ yes' : '❌ no'}"
  puts "Encryption match:       #{same_encryption ? '✅ yes (or no encryption cert required)' : '❌ no'}"
  puts

  if same_signing && same_encryption
    puts '✅ Certificates are the same -- safe to add metadata URL now.'
    puts '   Paste the URL into Advanced Settings -> IdP metadata URL and save.'
    puts '   RefreshAllSamlMetadataJob will handle rotation automatically (every 15 min).'
  else
    puts '⚠️  Certificates are different -- proceed with manual swap at maintenance window.'
  end

  { same_signing:, same_encryption: }
end
# rubocop:enable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/MethodLength, Metrics/PerceivedComplexity

# Check whether the primary SAML config has an IdP metadata URL set and whether
# it is reachable. Determines which scenario applies for a cert rotation ticket:
#   Scenario A (URL set)    -> cert rotations handled automatically, no downtime needed
#   Scenario B (no URL set) -> cert rotations require a manual admin panel update
#
# Usage:
#   check_saml_metadata_url
# rubocop:disable Metrics/AbcSize, Metrics/MethodLength
# :reek:TooManyStatements
# :reek:UncommunicativeVariableName
def check_saml_metadata_url
  config = Saml::Configuration.primary
  url = config.idp_metadata_url

  if url.blank?
    puts '⚠️  No IdP metadata URL configured (Scenario B -- static cert only).'
    puts '   Cert rotations require manual intervention.'
    puts '   Ask the tenant for their App Federation Metadata URL from Azure AD / Entra ID.'
    return nil
  end

  puts '✅ IdP metadata URL is set:'
  puts "   #{url}"
  puts "\nAttempting to fetch metadata..."

  begin
    parser = OneLogin::RubySaml::IdpMetadataParser.new
    settings = parser.parse(parser.send(:get_idp_metadata, url, true))
    cert_count = settings.idp_cert_multi[:signing]&.count || 0
    puts "✅ Reachable -- #{cert_count} signing cert(s) found in metadata."
    puts '   Cert rotations are handled automatically by RefreshAllSamlMetadataJob (every 15 min).'
  rescue StandardError => e
    puts "❌ Failed to fetch metadata: #{e.message}"
    puts '   The URL is set but may be unreachable or malformed.'
  end

  url
end
# rubocop:enable Metrics/AbcSize, Metrics/MethodLength

# ---------------------------------------------------------------------------- #
#                               Cheatsheet Method                              #
# ---------------------------------------------------------------------------- #

# rubocop:disable Metrics/MethodLength
# :reek:TooManyStatements
def saml_helper_cheatsheet
  puts "\n🚀🚀🚀 SAML HELPER -- VERSION #{SAML_HELPER_VERSION} 🚀🚀🚀"
  puts "\n📘 SAML Helper Cheatsheet:"
  puts "\n🔍 Config Inspection:"
  puts '• saml_config_summary                  -> Enabled state, debug/setup mode, metadata URL, cert count'
  puts '• check_saml_metadata_url              -> Scenario A vs B -- is the metadata URL set and reachable?'
  puts '• compare_saml_certs(url)              -> Compare stored certs vs new metadata URL (cert rotation triage)'
  puts "\n🛠 Debug Event Queries:"
  puts '• search_saml_debug_events(string)     -> Search failed SAML events by email or employee number'
  puts '• search_saml_events_by_user(user_id)  -> All SAML debug events for a user'
  puts '• latest_failed_saml_event             -> Most recent failed SAML login event'
  puts '• get_saml_request_response(user_id)   -> Raw SAML request/response for user'
  puts '• user_saml_login_successful?(user_id) -> Check if a user successfully authenticated'
end
# rubocop:enable Metrics/MethodLength

ConsoleHelpers.register_helper('saml', SAML_HELPER_VERSION, method(:saml_helper_cheatsheet))

saml_helper_cheatsheet

# rubocop:enable I18n/GetText/DecorateString, I18n/RailsI18n/DecorateString
