WORKFLOW_HELPER_VERSION = "0.1.0"
WORKFLOW_HELPER_VERSION = "0.1.1"
HELPER_VERSION = WORKFLOW_HELPER_VERSION
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
alias wfc workflow_helper_cheatsheet
ConsoleHelpers.register_helper("workflow", WORKFLOW_HELPER_VERSION, method(:workflow_helper_cheatsheet))
ConsoleHelpers.register_helper("workflow", WORKFLOW_HELPER_VERSION, method(:workflow_helper_cheatsheet))
WORKFLOW_HELPER_VERSION = "0.1.1"
HELPER_VERSION = WORKFLOW_HELPER_VERSION
def show_workflow_helper_guide
  # Prints the main workflow helper guide with available methods.
  # Example: wf
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

  alias wf show_workflow_helper_guide

  def workflow_helper_version
    puts "Workflow Helper version #{WORKFLOW_HELPER_VERSION}"
  end

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
      message = JSON.parse(params["Message"]) rescue {}
      message_id = message.dig("mail", "messageId")
      sns_message_type = params["Type"]
      ses_notification_type = message["notificationType"]
      subject = message.dig("mail", "commonHeaders", "subject") || "(no subject)"
      message_id = params["MessageId"]
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
  # Finds SNS messages from a specific sender email (in 'source').
  # Example: sns_by_email("gti.etl.integration@gtigrows.com")
  Apartment::Tenant.switch('public') do
    EmailProcessor::SNSMessage.where("params -> 'Message' -> 'mail' ->> 'source' = ?", email)
  end
end
def sns_by_to(email_address)
  Apartment::Tenant.switch('public') do
    EmailProcessor::SNSMessage
      .where("created_at > ?", 5.days.ago)
      .where("params -> 'Message' ILIKE ?", "%#{email_address}%")
  end
end
def public_sns_by_to(email_address)
  EmailProcessor::SNSMessage
  .where("created_at > ?", 5.days.ago)
  .where("params -> 'Message' ILIKE ?", "%#{email_address}%")
end

def sns_last
  # Finds the most recent SNS message.
  # Example: sns_last
  Apartment::Tenant.switch('public') do
    EmailProcessor::SNSMessage.order(created_at: :desc).first
  end
end

def sns_by_message_id(message_id)
  # Finds SNS messages containing a given message ID string.
  # Example: sns_by_message_id("07ef19cc-817d-5618-9788-79ac1d28d038")
  Apartment::Tenant.switch('public') do
    EmailProcessor::SNSMessage.where("params ->> 'Message' ILIKE ?", "%#{message_id}%")
  end
end

def sns_by_domain(domain)
  # Finds SNS messages where any recipient email includes the given domain.
  # Example: sns_by_domain("gtigrows.com")
  Apartment::Tenant.switch('public') do
    EmailProcessor::SNSMessage.where("params ->> 'Message' ILIKE ?", "%@#{domain}%")
  end
end

def sns_by_subject(subject)
  # Finds SNS messages with a subject that includes the given string.
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
  Apartment::Tenant.switch('public') do
    EmailProcessor::SNSMessage
      .where("params ->> 'Message' ILIKE ?", "%#{email.message_id.gsub(/[<>]/, '')}%")
      .first
  end
end

def email_for_sns(sns_msg)
  # Finds EmailProcessor::Email created for the given SNS message, if any.
  message_id = JSON.parse(sns_msg.params["Message"])["mail"]["messageId"]
  EmailProcessor::Email.find_by(message_id: message_id)
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
alias wfc workflow_helper_cheatsheet
workflow_helper_cheatsheet
