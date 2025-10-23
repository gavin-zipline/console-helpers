FEATURE_FLAGS_HELPER_VERSION = "0.4.0"

ConsoleHelpers.register_helper("feature_flags", FEATURE_FLAGS_HELPER_VERSION, method(:feature_flags_helper_cheatsheet))

def feature_flag_actors(feature_flag)
  actors = Flipper[feature_flag].actors_value
  shortname = Organization.current.shortname
  org_enabled = org_flag_enabled?(feature_flag)
  parsed_actors = parse_flipper_actors(actors)

  {
    shortname => {
      feature_flag: feature_flag,
      Organization: org_enabled,
      SecurityRoles: parsed_actors[:roles],
      Teams: parsed_actors[:teams],
      Users: parsed_actors[:users]
    }
  }
end

def parse_flipper_actors(actors)
  prefix = "gid://zipline-#{Organization.current.shortname}/"

  teams = []
  users = []
  roles = []
  org_ids = []

  actors.each do |actor|
    next if !actor.include?('/Organization/') && !actor.start_with?(prefix)

    if actor.include?('/Team/')
      teams << actor.split('/').last.to_i
    elsif actor.include?('/User/')
      users << actor.split('/').last.to_i
    elsif actor.include?('/SecurityRole/')
      roles << actor.split('/').last.to_i
    elsif actor.include?('/Organization/')
      org_ids << actor.split('/').last.to_i
    end
  end

  {
    teams: teams.uniq.sort,
    users: users.uniq.sort,
    roles: roles.uniq.sort,
    org_ids: org_ids
  }
end

def org_flag_enabled?(feature_flag)
  current_org_id = Organization.current.id
  org_ids = parse_flipper_actors(Flipper[feature_flag].actors_value)[:org_ids]
  current_org_id && org_ids.include?(current_org_id)
end

# Most common feature flag questions:
def flag_enabled_for_org?(feature_flag)
  org_flag_enabled?(feature_flag)
end

def flag_enabled_for_team?(feature_flag, team)
  Flipper[feature_flag].enabled?(team)
end

def flag_enabled_for_user?(feature_flag, user)
  Flipper[feature_flag].enabled?(user)
end

def all_flags_enabled_for_team(team)
  Flipper.features.select { |f| Flipper[f.name].enabled?(team) }.map(&:name).sort
end

def all_flags_enabled_for_user(user)
  Flipper.features.select { |f| Flipper[f.name].enabled?(user) }.map(&:name).sort
end

def all_flags_enabled_for_org
  Flipper.features.select { |f| org_flag_enabled?(f.name) }.map(&:name).sort
end

def teams_with_flag_enabled(feature_flag)
  team_ids = parse_flipper_actors(Flipper[feature_flag].actors_value)[:teams]
  Team.where(id: team_ids)
end

def feature_flags_helper_cheatsheet
  puts   "\n🚀🚀🚀 FEATURE FLAGS HELPER — VERSION #{FEATURE_FLAGS_HELPER_VERSION} 🚀🚀🚀"
  puts "\n📘 Feature Flags Helper Cheatsheet:"
  puts "\n� INVESTIGATION & DEBUGGING:"
  puts "• debug_user_feature(feature_flag, user)     → Why does/doesn't this user have this feature?"
  puts "• tenant_feature_overview(feature_flag)      → All gates for feature in current tenant"
  puts "• find_negation_gates(feature_flag)          → Show all negation gates for feature"
  puts "• compare_user_vs_team_access(feature_flag, user) → Compare user access vs their team access"
  puts "• feature_inheritance_chain(user)            → Show user → teams → org → security_role hierarchy"
  puts "\n🛠 BASIC QUERIES:"
  puts "• feature_flag_actors(feature_flag)          → Lists org/team/user/role actors per feature flag"
  puts "• org_flag_enabled?(feature_flag)            → Returns true if the feature is org-enabled"
  puts "• teams_with_flag_enabled(feature_flag)      → Returns Team records with the flag enabled"
  puts "• flag_enabled_for_org?(feature_flag)        → Returns true if flag is enabled for current org"
  puts "• flag_enabled_for_team?(feature_flag, team) → Returns true if flag is enabled for given team"
  puts "• flag_enabled_for_user?(feature_flag, user) → Returns true if flag is enabled for given user"
  puts "• all_flags_enabled_for_team(team)           → List of flags enabled for the given team"
  puts "• all_flags_enabled_for_user(user)           → List of flags enabled for the given user"
  puts "• all_flags_enabled_for_org                  → List of flags enabled for current org"
  puts "\n⚙️  MANAGEMENT & CONTROL:"
  puts "• enable_feature_for_user(feature_flag, user)     → Create enablement gate for user"
  puts "• disable_feature_for_user(feature_flag, user)    → Create negation gate for user"
  puts "• enable_feature_for_team(feature_flag, team)     → Create enablement gate for team"
  puts "• disable_feature_for_team(feature_flag, team)    → Create negation gate for team"
  puts "• remove_user_gates(feature_flag, user)           → Remove all gates for user (enablement & negation)"
  puts "• remove_team_gates(feature_flag, team)           → Remove all gates for team (enablement & negation)"
  puts "\n🔧 Usage Tips:"
  puts "• List all feature flags:           Flipper.features.map(&:name).sort"
  puts "• Enable/disable feature globally:  Flipper[:my_feature].enable / .disable"
  puts "• Remember: Negation gates (feature.negated) override enablement gates"
  puts "• Features.build(user: user).enabled?() respects negations, Flipper[].enabled?() does not"
end

# Flexible cheatsheet naming - support multiple conventions for convenience
alias feature_flags_cheatsheet feature_flags_helper_cheatsheet
alias feature_flag_cheatsheet feature_flags_helper_cheatsheet
alias feature_flag_helper_cheatsheet feature_flags_helper_cheatsheet

# ================================
# INVESTIGATION & DEBUGGING METHODS
# ================================

def debug_user_feature(feature_flag, user)
  puts "\n🔍 DEBUGGING: Why #{user.name} (ID: #{user.id}) #{Features.build(user: user).enabled?(feature_flag) ? 'HAS' : 'DOES NOT HAVE'} '#{feature_flag}'"
  puts

  # Check final result first
  user_has_feature = Features.build(user: user).enabled?(feature_flag)
  puts "🎯 FINAL RESULT: #{user_has_feature ? '✅ ENABLED' : '❌ DISABLED'}"
  puts

  # Check each level of access
  puts "📊 ACCESS BREAKDOWN:"

  # 1. Direct user enablement gate
  user_direct = Flipper[feature_flag].enabled?(user)
  puts "   User direct enablement: #{user_direct ? '✅ YES' : '❌ NO'}"

  # 2. Direct user negation gate
  user_negated = Flipper["#{feature_flag}.negated"].enabled?(user)
  puts "   User direct negation: #{user_negated ? '🚫 YES' : '✅ NO'}"

  # 3. SecurityRole access
  role_enabled = Flipper[feature_flag].enabled?(user.security_role)
  role_negated = Flipper["#{feature_flag}.negated"].enabled?(user.security_role)
  puts "   SecurityRole (#{user.security_role.name}) enablement: #{role_enabled ? '✅ YES' : '❌ NO'}"
  puts "   SecurityRole (#{user.security_role.name}) negation: #{role_negated ? '🚫 YES' : '✅ NO'}"

  # 4. Team access
  puts "   Team access:"
  user.teams.each do |team|
    team_enabled = Flipper[feature_flag].enabled?(team)
    team_negated = Flipper["#{feature_flag}.negated"].enabled?(team)
    puts "     - #{team.name}: enablement #{team_enabled ? '✅' : '❌'}, negation #{team_negated ? '🚫' : '✅'}"
  end

  # 5. Organization access
  org_enabled = Flipper[feature_flag].enabled?(Organization.current)
  org_negated = Flipper["#{feature_flag}.negated"].enabled?(Organization.current)
  puts "   Organization (#{Organization.current.name}) enablement: #{org_enabled ? '✅ YES' : '❌ NO'}"
  puts "   Organization (#{Organization.current.name}) negation: #{org_negated ? '🚫 YES' : '✅ NO'}"

  puts
  puts "🧠 LOGIC: Feature enabled if ANY enablement gate matches AND NO negation gate matches"
  puts "   Negation gates override enablement gates at any level"
end

def tenant_feature_overview(feature_flag)
  tenant = Organization.current.shortname
  puts "\n🏢 FEATURE OVERVIEW: '#{feature_flag}' in #{tenant}"
  puts

  # Enablement gates
  enablement_gates = Flipper::Adapters::ActiveRecord::Gate
    .where(feature_key: feature_flag)
    .where("value LIKE ? OR value LIKE ?",
           "%zipline-#{tenant}/%",
           "%Organization/#{Organization.current.id}%")

  puts "✅ ENABLEMENT GATES (#{enablement_gates.count}):"
  if enablement_gates.any?
    enablement_gates.each do |gate|
      actor_type = gate.value.split('/').last(2).first
      actor_id = gate.value.split('/').last
      puts "   #{actor_type}/#{actor_id}: #{gate.value}"
    end
  else
    puts "   None found"
  end

  puts

  # Negation gates
  negation_gates = Flipper::Adapters::ActiveRecord::Gate
    .where(feature_key: "#{feature_flag}.negated")
    .where("value LIKE ? OR value LIKE ?",
           "%zipline-#{tenant}/%",
           "%Organization/#{Organization.current.id}%")

  puts "🚫 NEGATION GATES (#{negation_gates.count}):"
  if negation_gates.any?
    negation_gates.each do |gate|
      actor_type = gate.value.split('/').last(2).first
      actor_id = gate.value.split('/').last
      puts "   #{actor_type}/#{actor_id}: #{gate.value}"
    end
  else
    puts "   None found"
  end

  puts
  puts "🎯 SUMMARY:"
  puts "   Total enablement gates: #{enablement_gates.count}"
  puts "   Total negation gates: #{negation_gates.count}"
  puts "   Negation gates override enablement gates"
end

def find_negation_gates(feature_flag)
  negation_key = "#{feature_flag}.negated"

  puts "\n🚫 NEGATION GATES for '#{feature_flag}'"
  puts

  # All negation gates (across all tenants)
  all_negation_gates = Flipper::Adapters::ActiveRecord::Gate.where(feature_key: negation_key)

  puts "🌍 ALL TENANTS (#{all_negation_gates.count} total):"
  tenant_groups = all_negation_gates.group_by do |gate|
    if (match = gate.value.match(/zipline-([^\/]+)\//))
      match[1]
    else
      'global'
    end
  end

  tenant_groups.each do |tenant_name, gates|
    puts "   #{tenant_name}: #{gates.count} gates"
    gates.each do |gate|
      actor_type = gate.value.split('/').last(2).first
      actor_id = gate.value.split('/').last
      puts "     #{actor_type}/#{actor_id}"
    end
  end
end

def compare_user_vs_team_access(feature_flag, user)
  puts "\n⚖️  COMPARING: User vs Team access for '#{feature_flag}'"
  puts

  user_has_feature = Features.build(user: user).enabled?(feature_flag)
  puts "👤 USER: #{user.name} → #{user_has_feature ? '✅ ENABLED' : '❌ DISABLED'}"
  puts

  puts "👥 TEAMS:"
  user.teams.each do |team|
    team_enabled = Flipper[feature_flag].enabled?(team)
    puts "   #{team.name} → #{team_enabled ? '✅ ENABLED' : '❌ DISABLED'}"
  end

  puts

  # Check for conflicts
  team_access = user.teams.any? { |team| Flipper[feature_flag].enabled?(team) }

  if team_access && !user_has_feature
    puts "⚠️  CONFLICT: User's teams have access but user is blocked"
    puts "   → Likely cause: Negation gate for user or SecurityRole"
  elsif !team_access && user_has_feature
    puts "⚠️  CONFLICT: User has access but teams don't"
    puts "   → Likely cause: Direct user enablement gate or SecurityRole access"
  else
    puts "✅ CONSISTENT: User and team access align"
  end
end

def feature_inheritance_chain(user)
  puts "\n🔗 FEATURE INHERITANCE CHAIN for #{user.name} (ID: #{user.id})"
  puts
  puts "   User: #{user.name}"
  puts "   └─ SecurityRole: #{user.security_role.name} (Level: #{user.security_role.level})"
  puts "   └─ Teams: #{user.teams.map(&:name).join(', ')}"
  puts "   └─ Organization: #{Organization.current.name} (#{Organization.current.shortname})"
  puts
  puts "💡 Feature resolution order:"
  puts "   1. User-specific negation gates (block everything)"
  puts "   2. SecurityRole negation gates (block everything)"
  puts "   3. Team negation gates (block everything)"
  puts "   4. Organization negation gates (block everything)"
  puts "   5. User-specific enablement gates (grant access)"
  puts "   6. SecurityRole enablement gates (grant access)"
  puts "   7. Team enablement gates (grant access)"
  puts "   8. Organization enablement gates (grant access)"
  puts "   9. Global feature state (default)"
end

# ================================
# MANAGEMENT & CONTROL METHODS
# ================================

def enable_feature_for_user(feature_flag, user)
  tenant = Organization.current.shortname
  gate_value = "gid://zipline-#{tenant}/User/#{user.id}"

  # Remove any existing negation first
  existing_negation = Flipper::Adapters::ActiveRecord::Gate.where(
    feature_key: "#{feature_flag}.negated",
    key: 'actors',
    value: gate_value
  ).first

  if existing_negation
    existing_negation.destroy
    puts "🗑️  Removed negation gate for #{user.name}"
  end

  # Create enablement gate
  Flipper[feature_flag].enable(user)
  puts "✅ Enabled '#{feature_flag}' for #{user.name}"
end

def disable_feature_for_user(feature_flag, user)
  tenant = Organization.current.shortname
  gate_value = "gid://zipline-#{tenant}/User/#{user.id}"

  # Create negation gate (this will override any enablement)
  Flipper::Adapters::ActiveRecord::Gate.create!(
    feature_key: "#{feature_flag}.negated",
    key: 'actors',
    value: gate_value
  )
  puts "🚫 Created negation gate for '#{feature_flag}' for #{user.name}"
  puts "   This will block access even if user's teams have the feature"
end

def enable_feature_for_team(feature_flag, team)
  Flipper[feature_flag].enable(team)
  puts "✅ Enabled '#{feature_flag}' for team: #{team.name}"
end

def disable_feature_for_team(feature_flag, team)
  tenant = Organization.current.shortname
  gate_value = "gid://zipline-#{tenant}/Team/#{team.id}"

  # Create negation gate
  Flipper::Adapters::ActiveRecord::Gate.create!(
    feature_key: "#{feature_flag}.negated",
    key: 'actors',
    value: gate_value
  )
  puts "🚫 Created negation gate for '#{feature_flag}' for team: #{team.name}"
end

def remove_user_gates(feature_flag, user)
  tenant = Organization.current.shortname
  gate_value = "gid://zipline-#{tenant}/User/#{user.id}"

  # Remove enablement gate
  enablement_gate = Flipper::Adapters::ActiveRecord::Gate.where(
    feature_key: feature_flag,
    key: 'actors',
    value: gate_value
  ).first

  # Remove negation gate
  negation_gate = Flipper::Adapters::ActiveRecord::Gate.where(
    feature_key: "#{feature_flag}.negated",
    key: 'actors',
    value: gate_value
  ).first

  removed = []
  if enablement_gate
    enablement_gate.destroy
    removed << "enablement"
  end

  if negation_gate
    negation_gate.destroy
    removed << "negation"
  end

  if removed.any?
    puts "🗑️  Removed #{removed.join(' and ')} gate(s) for #{user.name}"
  else
    puts "ℹ️  No gates found for #{user.name}"
  end
end

def remove_team_gates(feature_flag, team)
  tenant = Organization.current.shortname
  gate_value = "gid://zipline-#{tenant}/Team/#{team.id}"

  # Remove enablement gate
  enablement_gate = Flipper::Adapters::ActiveRecord::Gate.where(
    feature_key: feature_flag,
    key: 'actors',
    value: gate_value
  ).first

  # Remove negation gate
  negation_gate = Flipper::Adapters::ActiveRecord::Gate.where(
    feature_key: "#{feature_flag}.negated",
    key: 'actors',
    value: gate_value
  ).first

  removed = []
  if enablement_gate
    enablement_gate.destroy
    removed << "enablement"
  end

  if negation_gate
    negation_gate.destroy
    removed << "negation"
  end

  if removed.any?
    puts "🗑️  Removed #{removed.join(' and ')} gate(s) for team: #{team.name}"
  else
    puts "ℹ️  No gates found for team: #{team.name}"
  end
end

feature_flags_helper_cheatsheet
