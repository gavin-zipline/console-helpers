
USER_HELPER_VERSION = "1.4.1"
if defined?(ConsoleHelpers) && respond_to?(:user_helper_cheatsheet)
  ConsoleHelpers.register_helper("user", USER_HELPER_VERSION, method(:user_helper_cheatsheet))
end

# == User Console Helper ==
# Tools for investigating and debugging user-related data in the console
def impersonate_user(target_user)
  service_user = User.find_by(email: "service@retailzipline.com")
  raise "Service account not found" unless service_user

  # Notify if target user is disabled or terminated
  puts "⚠️ Target user #{target_user.name} (#{target_user.id}) is DISABLED." if target_user.disabled?
  puts "⚠️ Target user #{target_user.name} (#{target_user.id}) is TERMINATED." unless target_user.employed?

  # Align security role
  service_user.update!(security_role: target_user.security_role) if target_user.security_role

  # Optionally align org role and permissions
  org_role = target_user.org_role
  service_user.align_permissions!(org_role.permissions) if org_role

  # Copy feature flags
  target_user.feature_flags.each do |flag|
    Flipper.enable(flag, service_user)
  end

  # Add to all target user's teams
  target_user.teams.each do |team|
    service_user.teams << team unless service_user.teams.include?(team)
  end

  # Copy preferences
  if target_user.preferences.present?
    service_user.update!(preferences: target_user.preferences)
  end

  puts "✅ Service account is now impersonating #{target_user.name} (#{target_user.id})"
  service_user
end

def reset_service_account
  User::ServiceUser.reset!
  service_user = User::ServiceUser.user

  # Reset feature flags
  Flipper.features.each { |flag| Flipper.disable(flag.key, service_user) }

  # Reset security role
  service_user.update!(security_role: SecurityRole.default)

  # Reset preferences
  service_user.update!(time_zone: 'UTC', locale: 'en')

  puts "✅ Service Account has been reset to default state."
  service_user
end


def find_user(param)
  return User.find_by(id: param) if param.is_a?(Integer)

  if param.is_a?(String)
    return User.where("LOWER(email) = :val OR employee_number = :val OR LOWER(username) = :val", val: param.downcase)
  end

  if param.is_a?(Hash)
    return User.where(param)
  end

  raise ArgumentError, "Unsupported input type for find_user: #{param.class}"
end

class User
  def summary
    {
      id: id,
      name: name,
      employee_number: employee_number,
      username: username,
      email: email,
      employed: respond_to?(:employed?) ? employed? : !deleted_at.present?,
      disabled: respond_to?(:disabled?) ? disabled? : nil,
      teams_count: teams.count,
      team_names: teams.pluck(:name),
      permissions: respond_to?(:permissions) ? permissions.pluck(:name) : [],
      last_audit_summary: audits.order(created_at: :desc).limit(1).map do |audit|
        {
          action: audit.action,
          audited_changes: audit.audited_changes,
          created_at: audit.created_at
        }
      end.first
    }
  end

  def user_set
    team_membership = team_memberships.first
    context = team_membership&.to_user_context

    [self, context]
  end

  def org_role
    OrganizationRole.find_by(name: self.title)
  end
  # solves the problem or preferences allway showing up as changed in user audits
  def audits_without_preferences
    self.audits.reject do |audit|
      audit.audited_changes.key?("preferences")
    end
  end

  def enable_feature_flag(flag)
    Flipper.enable(flag, self)
  end

  def disable_feature_flag(flag)
    Flipper.disable(flag, self)
  end

  def previous_team
    return nil unless respond_to?(:team_memberships)

    memberships = team_memberships.with_deleted.order(created_at: :asc)
    return nil if memberships.size < 2

    previous_membership = memberships[-2]
    previous_membership&.team
  end

  def teams_history
    return [] unless respond_to?(:team_memberships)

    team_memberships.with_deleted.order(:created_at).map do |tm|
      {
        team: tm.team&.name || "(no team)",
        joined: "#{tm.created_at.strftime("%Y-%m-%d")} (#{time_ago_in_words(tm.created_at)} ago)",
        left: tm.deleted_at ? "#{tm.deleted_at.strftime("%Y-%m-%d")} (#{time_ago_in_words(tm.deleted_at)} ago)" : "Still active",
        active: tm.deleted_at.nil?
      }
    end
  end

  def merge_all_bookmarks
    disable_return_printing

    return unless team_memberships.exists?

    most_recent_team_id = team_memberships.order(created_at: :desc).limit(1).pluck(:team_id).first

    unless most_recent_team_id
      puts "⚠️  No recent team found for user #{id}."
      enable_return_printing
      return
    end

    bookmarks = Bookmark.where(user_id: id)
    moved = 0
    already_present = 0

    if bookmarks.exists?
      puts "🔄 Evaluating #{bookmarks.count} bookmarks for user #{id}..."

      bookmarks.each do |bookmark|
        conflict = Bookmark.find_by(
          user_id: id,
          team_id: most_recent_team_id,
          target_id: bookmark.target_id,
          target_type: bookmark.target_type
        )

        if conflict
          already_present += 1
        else
          bookmark.update!(team_id: most_recent_team_id)
          moved += 1
        end
      end

      puts "✅ Bookmarks merged for user #{id}: #{moved} moved, #{already_present} already present."
    else
      puts "ℹ️ No bookmarks found for user #{id}."
    end

    enable_return_printing
  end

  private

  def time_ago_in_words(timestamp)
    seconds = (Time.current - timestamp).to_i
    minutes = seconds / 60
    hours = minutes / 60
    days = hours / 24

    return "#{days} days" if days > 0
    return "#{hours} hours" if hours > 0
    return "#{minutes} minutes" if minutes > 0
    "#{seconds} seconds"
  end
end

# == Cheatsheet ==
# UserHelper.find_user("someone@example.com")          # => Find user by email, employee number, or username
# UserHelper.find_user(123)                            # => Find user by ID
# UserHelper.find_user({email: "someone@example.com"}) # => Find user(s) using any attribute hash
# UserHelper.user_context(user)                        # => Get user's first team membership context
# UserHelper.employed?(user)                           # => Check if user is employed
# UserHelper::VERSION                                  # => "1.0.0"
# user.user_summary                                     # => View key info about the user (runtime instance method)
# user.user_set                                         # => Get [user, user_context] tuple (runtime instance method)

def align_users_to_org_roles(users)
  users.each do |user|
    org_role = user.org_role

    if org_role.nil?
      puts "⚠️  No org role found for user #{user.name} (#{user.id})"
      next
    end

    puts "🔧 Aligning #{user.name} (#{user.id}) to org role #{org_role.name}"
    user.align_permissions!(org_role.permissions)
    puts "✅ Permissions updated"
  end
end

def user_helper_cheatsheet
  puts   "\n🚀🚀🚀 USER HELPER — VERSION #{USER_HELPER_VERSION} 🚀🚀🚀"
  puts "\n📘 User Helper Cheatsheet:"
  puts "\n🛠 Methods:"
  puts "• find_user(param)                    → Smart finder by ID, email, username, or attribute hash"
  puts "• user.summary                        → Key attributes + most recent audit summary"
  puts "• user.user_set                       → Returns [user, user_context] for convenience"
  puts "• user.org_role                       → Get org role from user title"
  puts "• user.audits_without_preferences     → Audits excluding 'preferences' noise"
  puts "• align_users_to_org_roles(users)     → Align org role permissions for a set of users"
  puts "• user.enable_feature_flag(flag)       → Enable a Flipper feature flag for the user"
  puts "• user.disable_feature_flag(flag)      → Disable a Flipper feature flag for the user"
  puts "• user.teams_history                  → Chronological history of user's team memberships"
  puts "• user.previous_team                  → Returns the user's previous team if they recently switched"
  puts "• user.merge_all_bookmarks            → Merge all user's bookmarks to most recently joined team"
  puts "• reset_service_account                  → Resets the service account to its default clean state"
end

user_helper_cheatsheet

def users_by_name(names)
  disable_return_printing

  found_users = []
  missing_names = []

  names.each do |raw_name|
    next if raw_name.blank?

    clean_name = raw_name.strip

    delimiter_match = clean_name.match(/[^a-zA-Z]/)
    delimiter = delimiter_match[0] if delimiter_match

    parts = delimiter ? clean_name.split(delimiter) : [clean_name]

    if parts.size >= 2
      normalized_name = parts.map(&:strip).join(' ')
    else
      normalized_name = parts.first.strip
    end

    formatted_name = normalized_name.downcase.split.map(&:capitalize).join(' ')

    user = User.where("LOWER(name) = ?", formatted_name.downcase).first

    if user.nil? && parts.size >= 2 && parts.first.length == 1
      first_initial = parts.first.downcase
      family_name = parts.last.strip.downcase

      puts "🔎 Fallback search by first initial '#{first_initial}' and family name '#{family_name}'"

      user = User.where(
        "LOWER(family_name) = ? AND LOWER(given_name) LIKE ?",
        family_name, "#{first_initial}%"
      ).first

      if user.nil? && family_name.length > 4
        family_name_prefix = family_name[0..4]

        puts "🔎 Fuzzy fallback: family_name starts with '#{family_name_prefix}' and given_name initial '#{first_initial}'"

        user = User.where(
          "LOWER(family_name) LIKE ? AND LOWER(given_name) LIKE ?",
          "#{family_name_prefix}%", "#{first_initial}%"
        ).first
      end
    end

    if user
      puts "✅ '#{raw_name}' matched '#{user.name}' (#{user.id})"
      found_users << user
    else
      puts "❌ No match for '#{raw_name}'. Attempted search variants: #{[formatted_name, family_name, family_name_prefix].compact.uniq.join(', ')}"
      missing_names << raw_name
    end
  end

  puts "\n🔍 Summary:"
  puts "• Found #{found_users.size} users."
  puts "• #{missing_names.size} names did not match any user."

  enable_return_printing
  found_users
end
