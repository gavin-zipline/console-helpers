WORKFLOW_HELPER_VERSION = "0.1.3"
def workflow_helper_cheatsheet
  puts   "\n🚀🚀🚀 WORKFLOW HELPER — VERSION #{WORKFLOW_HELPER_VERSION} 🚀🚀🚀"
  puts "\n📘 Workflow Helper Cheatsheet:"
  puts "\n🛠 General:"
  puts "• wf                                      → Show the Workflow Helper guide"
  puts "• wfc                                     → Print this cheatsheet"
  puts "• workflow_helper_version                 → Show current version"
  puts "\n🔍 Lookup Methods:"
  puts "• workflow_by_domain(domain)              → Find a workflow by sender domain"
  puts "• list_workflow_rules(workflow)           → List rules for a workflow"
  puts "• workflow_email_for(team_or_id)          → Get workflow email for a team or ID"
  puts "• workflow_to_email_addresses             → List all open teams with their workflow email"
  puts "\n📨 SNS Lookup:"
  puts "• sns_last                                → Most recent SNS message"
  puts "• get_sns_messages(since: 1.week.ago)     → SNS messages for current org (in public tenant)"
  puts "• sns_by_email(email)                     → SNS messages by sender"
  puts "• sns_by_to(email_address)                → SNS messages with recipient"
  puts "• public_sns_by_to(email_address)         → Same as above, without tenant switching"
  puts "• sns_by_message_id(message_id)           → SNS messages by ID match"
  puts "• sns_by_domain(domain)                   → SNS messages with recipient domain"
  puts "• sns_by_subject(subject)                 → SNS messages by subject"
  puts "• sns_for_email(email)                    → SNS message that triggered given email"
  puts "\n✉️ Email Lookup:"
  puts "• emails_by_subject(subject)              → Emails by subject"
  puts "• emails_by_message_id(message_id)        → Emails by exact message ID"
  puts "• emails_by_email(email)                  → Emails by from address"
  puts "• email_for_sns(sns_msg)                  → Email triggered by SNS message"
  puts "\n⚙️ Configuration:"
  puts "• check_feature_flags                     → List required workflow feature flags"
  puts "• list_internal_workflow_emails           → Teams with internal workflow email addresses"
  puts <<~GUIDE

    # ---------------------------------------------------------------------------- #
    #                   Zipline Workflow Helper Guide (v0.1.0)                    #
    # ---------------------------------------------------------------------------- #


    # ---------------------------- Class Enhancements ---------------------------- #
    Team.workflow_email(team_or_id)         # Get the workflow email for a team or team ID
    ProcessorEmail::Email: sns_msg.info     # Print summary info for an SNSMessage (checks Notification type, SES type, status, subject, etc.)
    sns_msg.info or sns_msgs.info

    # ------------------------------ Lookup Methods ------------------------------ #
    workflow_by_domain(domain)         # Find a workflow by sender domain
    list_workflow_rules(workflow)           # List rules and their actions for a workflow
    sns_by_email(email)                 # Find SNS messages from a specific sender



    sns_by_message_id(id)               # Find SNS messages containing a specific message ID
    sns_by_domain(domain)               # Find SNS messages with recipient emails at a given domain
    sns_by_subject(subject)             # Find SNS messages with a subject containing the given text
    emails_by_subject(subject)            # Find EmailProcessor::Email records matching subject
    emails_by_message_id(message_id)      # Find EmailProcessor::Email by exact message ID
    emails_by_sender(email)               # Find EmailProcessor::Email records by 'from' address

    # --------------------------- Configuration Checks --------------------------- #
    check_feature_flags(org)                # Check required feature flags for workflows
    list_internal_workflow_emails           # List teams with internal workflow email addresses

    # -------------------------- Admin Actions (Planned) ------------------------- #
    # simulate_trigger(...)                 # Simulate whether a subject/body would trigger a rule
    # inspect_inbound_email(...)            # View an inbound email and any rejection reasons
    # list_recent_inbound_emails(...)       # Show recent workflow-triggering emails

    Call `wf` at any time to view this guide.

    GUIDE
end

# Flexible cheatsheet naming - support multiple conventions for convenience
alias workflows_cheatsheet workflow_helper_cheatsheet
alias workflows_helper_cheatsheet workflow_helper_cheatsheet

ConsoleHelpers.register_helper("workflow", WORKFLOW_HELPER_VERSION, method(:workflow_helper_cheatsheet))

  # ---------------------------------------------------------------------------- #
  #                              Class Enhancements                              #
  # ---------------------------------------------------------------------------- #

  # add .workflow_email method to Team class
  class Team
    def workflow_email
      "tid.#{id}-workflows-#{Organization.current.shortname}@inbound.retailzipline.com"
    end
  end
  class EmailProcessor::SNSMessage < ApplicationRecord
    def info
      # Safely parse JSON and use dig for all deep access
      message = JSON.parse(params["Message"]) rescue {}
      message_id = message.dig("mail", "messageId") || params["MessageId"]
      sns_message_type = params["Type"]
      ses_notification_type = message["notificationType"]
      subject = message.dig("mail", "commonHeaders", "subject") || "(no subject)"
      error = self.error.presence || "(no error)"

      puts "--- Notification Info ---"
      puts "message ID/S3 key: #{message_id}"
      puts "SNS Message Type: #{sns_message_type} (#{sns_message_type == 'Notification' ? '✓' : '✗ fail'})"
      puts "SES Notification Type: #{ses_notification_type} (#{ses_notification_type == 'Received' ? '✓' : '✗ fail'})"
      puts "Processing Status: #{status} (#{status == 'complete' ? '✓' : '✗ fail'})"
      puts "Subject: #{subject}"
      puts "Message ID: #{message_id}"
      puts "Error: #{error}"
      puts "-------------------------"
    end

    def source
      # Safely dig for source address
      JSON.parse(params["Message"]).dig("mail", "source") rescue nil
    end
  end

  # ---------------------------------------------------------------------------- #
  #                                Lookup methods                                #
  # ---------------------------------------------------------------------------- #

  def list_workflow_rules(workflow)
    return [] unless workflow

    workflow.rules.map do |rule|
      {
        match_type: rule['match_type'],
        match_value: rule['match_value'],
        action: rule['action_type'],
        priority: rule['priority'],
        targets: rule['targets']
      }
    end
  end


def sns_by_email(email)
  # Uses public tenant. Finds SNS messages from a specific sender email (in 'source').
  # Example: sns_by_email("gti.etl.integration@gtigrows.com")
  Apartment::Tenant.switch('public') do
    EmailProcessor::SNSMessage.where("params ->> 'Message' ILIKE ?", "%\"source\":\"#{email}\"%")
  end
end
def sns_by_to(email_address)
  # Uses public tenant. Finds SNS messages with recipient.
  Apartment::Tenant.switch('public') do
    EmailProcessor::SNSMessage
      .where("created_at > ?", 5.days.ago)
      .where("params -> 'Message' ILIKE ?", "%#{email_address}%")
  end
end
def public_sns_by_to(email_address)
  # Uses current tenant. Finds SNS messages with recipient.
  EmailProcessor::SNSMessage
    .where("created_at > ?", 5.days.ago)
    .where("params -> 'Message' ILIKE ?", "%#{email_address}%")
end

def sns_last
  # Uses public tenant. Finds the most recent SNS message.
  # Example: sns_last
  Apartment::Tenant.switch('public') do
    EmailProcessor::SNSMessage.order(created_at: :desc).first
  end
end

def sns_by_message_id(message_id)
  # Uses public tenant. Finds SNS messages containing a given message ID string.
  # Example: sns_by_message_id("07ef19cc-817d-5618-9788-79ac1d28d038")
  Apartment::Tenant.switch('public') do
    EmailProcessor::SNSMessage.where("params ->> 'Message' ILIKE ?", "%#{message_id}%")
  end
end

def sns_by_domain(domain)
  # Uses public tenant. Finds SNS messages where any recipient email includes the given domain.
  # Example: sns_by_domain("gtigrows.com")
  Apartment::Tenant.switch('public') do
    EmailProcessor::SNSMessage.where("params ->> 'Message' ILIKE ?", "%@#{domain}%")
  end
end

def sns_by_subject(subject)
  # Uses public tenant. Finds SNS messages with a subject that includes the given string.
  # Example: sns_by_subject("Daily Recap")
  Apartment::Tenant.switch('public') do
    EmailProcessor::SNSMessage.where("params -> 'Message' -> 'mail' -> 'commonHeaders' ->> 'subject' ILIKE ?", "%#{subject}%")
  end
end

def emails_by_subject(subject)
  EmailProcessor::Email.where("subject ILIKE ?", "%#{subject}%")
end

def emails_by_message_id(message_id)
  # Finds EmailProcessor::Email by exact message ID.
  # Example: email_by_message_id("705524ce-d444-5e8d-8bc1-44ad95da3ee1")
  EmailProcessor::Email.where(message_id: message_id)
end

def emails_by_email(email)
  # Finds EmailProcessor::Email records from the given 'from' email address.
  # Example: email_by_sender("gti.etl.integration@gtigrows.com")
  EmailProcessor::Email.where("from ILIKE ?", "%#{email}%")
end

# ---------------------------------------------------------------------------- #
#                             Configuration Checks                             #
# ---------------------------------------------------------------------------- #

# Fetch recent SNS messages from the public tenant for the current org
# Default timeframe is 1.week.ago; pass :all to get all time
def get_sns_messages(since: 1.week.ago)
  # Uses public tenant. Fetch recent SNS messages for the current org
  original_shortname = Organization.current.shortname

  messages = Apartment::Tenant.switch('public') do
    scope = EmailProcessor::SNSMessage.all
    scope = scope.where('created_at > ?', since) unless since == :all
    scope.where("params ->> 'Message' LIKE ?", "%#{original_shortname}%").to_a
  end

  timestamp_info = since == :all ? "SNS messages (org: #{original_shortname})" :
    "SNS messages since #{since.strftime('%Y-%m-%d %H:%M')} (org: #{original_shortname})"

  puts "\n📨 Found #{messages.count} #{timestamp_info}"
  messages
end

def workflow_email_for(team_or_id)
  team = team_or_id.is_a?(Team) ? team_or_id : Team.by(id: team_or_id)
  return nil unless team
  team.workflow_email
end

def workflow_by_domain(domain)
  # Finds a workflow associated with a given sender domain.
  # Example: workflow_by_domain("gtigrows.com")
  Workflow.where("source_domain ILIKE ?", "%#{domain}%").first
end

def workflow_to_email_addresses
  Team.open.find_each.map do |team|
    {
      team_id: team.id,
      team_name: team.name,
      workflow_email: "tid.#{team.id}-workflows-#{Organization.current.shortname}@inbound.retailzipline.com"
    }
  end
end

def check_feature_flags
  {
    field_publishing_priority: FeatureFlag.enabled?(:'field.publishing.priority'),
    field_communication_notices: FeatureFlag.enabled?(:'field.communication-notices')
  }
end

def sns_for_email(email)
  # Uses public tenant. Finds SNS message that triggered given email.
  Apartment::Tenant.switch('public') do
    EmailProcessor::SNSMessage
      .where("params ->> 'Message' ILIKE ?", "%#{email.message_id.gsub(/[<>]/, '')}%")
      .first
  end
end

def email_for_sns(sns_msg)
  # Finds EmailProcessor::Email created for the given SNS message, if any. Uses dig for safety.
  message = JSON.parse(sns_msg.params["Message"]) rescue {}
  message_id = message.dig("mail", "messageId")
  EmailProcessor::Email.find_by(message_id: message_id)
end

# ################################################################################
# Investigation & Trace Helpers
# ################################################################################

def investigate_workflow_communication(subject: nil, team_id: nil, email: nil)
  puts "\n=== Workflow Communication Investigation ==="
  if team_id
    team = Team.by(id: team_id)
    if team
      puts "Team: #{team.name} (ID: #{team.id})"
      w_email = team.workflow_email
      puts "Workflow Email: #{w_email}"
    else
      puts "No team found for ID: #{team_id}"
      return
    end
  end

  if subject
    puts "\nLooking up workflows by subject: '#{subject}'"
    emails = emails_by_subject(subject)
    if emails.any?
      puts "Found #{emails.count} email(s) with subject. Message IDs: #{emails.map(&:message_id).join(", ")}"
    else
      puts "No emails found with subject: '#{subject}'"
    end
    sns_msgs = sns_by_subject(subject)
    if sns_msgs.any?
      puts "Found #{sns_msgs.count} SNS message(s) with subject. IDs: #{sns_msgs.map(&:id).join(", ")}"
    else
      puts "No SNS messages found with subject: '#{subject}'"
    end
  end

  if email
    puts "\nLooking up by email: #{email}"
    emails = emails_by_email(email)
    if emails.any?
      puts "Found #{emails.count} email(s) from #{email}. Message IDs: #{emails.map(&:message_id).join(", ")}"
    else
      puts "No emails found from: #{email}"
    end
    sns_msgs = sns_by_email(email)
    if sns_msgs.any?
      puts "Found #{sns_msgs.count} SNS message(s) from #{email}. IDs: #{sns_msgs.map(&:id).join(", ")}"
    else
      puts "No SNS messages found from: #{email}"
    end
  end

  if team_id && !subject && !email
    # Show recent workflow emails and SNS for the team
    puts "\nRecent workflow emails for team:"
    recent_workflow_emails(team_id).each do |em|
      puts "  Email: #{em.subject} (#{em.created_at}) [msgid: #{em.message_id}]"
    end
    puts "\nRecent SNS messages for team:"
    recent_sns_messages(team_id).each do |sns|
      puts "  SNS: #{sns.id} (#{sns.created_at})"
    end
  end
  puts "\n=== End Investigation ==="
end

def recent_workflow_emails(team_or_id, limit = 10)
  team = team_or_id.is_a?(Team) ? team_or_id : Team.by(id: team_or_id)
  return [] unless team
  EmailProcessor::Email.where("to ILIKE ?", "%tid.#{team.id}-workflows-%").order(created_at: :desc).limit(limit)
end

def recent_sns_messages(team_or_id, limit = 10)
  team = team_or_id.is_a?(Team) ? team_or_id : Team.by(id: team_or_id)
  return [] unless team
  Apartment::Tenant.switch('public') do
    EmailProcessor::SNSMessage.where("params ->> 'Message' ILIKE ?", "%tid.#{team.id}-workflows-%").order(created_at: :desc).limit(limit)
  end
end

# --- Improved absence/error reporting for lookup methods ---
def emails_by_subject(subject)
  emails = EmailProcessor::Email.where("subject ILIKE ?", "%#{subject}%")
  puts "No emails found with subject: '#{subject}'" if emails.empty?
  emails
end

def emails_by_message_id(message_id)
  emails = EmailProcessor::Email.where(message_id: message_id)
  puts "No emails found with message ID: #{message_id}" if emails.empty?
  emails
end

def emails_by_email(email)
  emails = EmailProcessor::Email.where("from ILIKE ?", "%#{email}%")
  puts "No emails found from: #{email}" if emails.empty?
  emails
end

def sns_by_email(email)
  sns_msgs = Apartment::Tenant.switch('public') do
    EmailProcessor::SNSMessage.where("params ->> 'Message' ILIKE ?", "%\"source\":\"#{email}\"%")
  end
  puts "No SNS messages found from: #{email}" if sns_msgs.empty?
  sns_msgs
end

def sns_by_subject(subject)
  sns_msgs = Apartment::Tenant.switch('public') do
    EmailProcessor::SNSMessage.where("params -> 'Message' -> 'mail' -> 'commonHeaders' ->> 'subject' ILIKE ?", "%#{subject}%")
  end
  puts "No SNS messages found with subject: '#{subject}'" if sns_msgs.empty?
  sns_msgs
end

def workflow_helper_cheatsheet
  puts   "\n🚀🚀🚀 WORKFLOW HELPER — VERSION #{WORKFLOW_HELPER_VERSION} 🚀🚀🚀"
  puts "\n📘 Workflow Helper Cheatsheet:"
  puts "\n🛠 General:"
  puts "• wf                                      → Show the Workflow Helper guide"
  puts "• wfc                                     → Print this cheatsheet"
  puts "• workflow_helper_version                 → Show current version"
  puts "\n🔍 Lookup Methods:"
  puts "• workflow_by_domain(domain)              → Find a workflow by sender domain"
  puts "• list_workflow_rules(workflow)           → List rules for a workflow"
  puts "• workflow_email_for(team_or_id)          → Get workflow email for a team or ID"
  puts "• workflow_to_email_addresses             → List all open teams with their workflow email"
  puts "\n📨 SNS Lookup:"
  puts "• sns_last                                → Most recent SNS message"
  puts "• get_sns_messages(since: 1.week.ago)     → SNS messages for current org (in public tenant)"
  puts "• sns_by_email(email)                     → SNS messages by sender"
  puts "• sns_by_to(email_address)                → SNS messages with recipient"
  puts "• public_sns_by_to(email_address)         → Same as above, without tenant switching"
  puts "• sns_by_message_id(message_id)           → SNS messages by ID match"
  puts "• sns_by_domain(domain)                   → SNS messages with recipient domain"
  puts "• sns_by_subject(subject)                 → SNS messages by subject"
  puts "• sns_for_email(email)                    → SNS message that triggered given email"
  puts "\n✉️ Email Lookup:"
  puts "• emails_by_subject(subject)              → Emails by subject"
  puts "• emails_by_message_id(message_id)        → Emails by exact message ID"
  puts "• emails_by_email(email)                  → Emails by from address"
  puts "• email_for_sns(sns_msg)                  → Email triggered by SNS message"
  puts "\n⚙️ Configuration:"
  puts "• check_feature_flags                     → List required workflow feature flags"
  puts "• list_internal_workflow_emails           → Teams with internal workflow email addresses"
end
workflow_helper_cheatsheet
