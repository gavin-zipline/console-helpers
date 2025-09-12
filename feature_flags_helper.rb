FEATURE_FLAGS_HELPER_VERSION = "0.1.0"
def feature_flags_helper_cheatsheet
  puts "\n📘 Feature Flags Helper Cheatsheet:"
  puts "• Add your feature flags helper methods here."
end
ConsoleHelpers.register_helper("feature_flags", FEATURE_FLAGS_HELPER_VERSION, method(:feature_flags_helper_cheatsheet))
FEATURE_FLAGS_HELPER_VERSION = "0.3.2"
HELPER_VERSION = FEATURE_FLAGS_HELPER_VERSION

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
  puts "\n🛠 Methods:"
  puts "• feature_flag_actors(feature_flag)          → Lists org/team/user/role actors per feature flag"
  puts "• org_flag_enabled?(feature_flag)            → Returns true if the feature is org-enabled"
  puts "• teams_with_flag_enabled(feature_flag)      → Returns Team records with the flag enabled"
  puts "• flag_enabled_for_org?(feature_flag)        → Returns true if flag is enabled for current org"
  puts "• flag_enabled_for_team?(feature_flag, team) → Returns true if flag is enabled for given team"
  puts "• flag_enabled_for_user?(feature_flag, user) → Returns true if flag is enabled for given user"
  puts "• all_flags_enabled_for_team(team)   → List of flags enabled for the given team"
  puts "• all_flags_enabled_for_user(user)   → List of flags enabled for the given user"
  puts "• all_flags_enabled_for_org           → List of flags enabled for current org"
  puts "\n🔧 Usage Tips:"
  puts "• List all feature flags:           Flipper.features.map(&:name).sort"
  puts "• Enable/disable feature globally:  Flipper[:my_feature].enable / .disable"
  puts "• Enable for specific actor types:  Flipper[:my_feature].enable Flipper::Actor.new(User.find(123))"
  puts "• Enable for org by GID:             Flipper[:my_feature].enable \"gid://zipline/Organization/530\""
  puts "• Check if enabled for actor:       Flipper[:my_feature].enabled?(Flipper::Actor.new(User.find(123)))"
end

feature_flags_helper_cheatsheet
