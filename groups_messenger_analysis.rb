# Analysis script for groups.messenger feature flag
# To understand current state and identify Associate Security Level users

def analyze_groups_messenger_flag
  puts "=== Groups Messenger Feature Flag Analysis ==="
  puts "Date: #{Time.current}"
  puts "Organization: #{Organization.current.name} (#{Organization.current.shortname})"
  puts

  # Check if the feature flag exists
  feature_flag = 'groups.messenger'
  unless Features::FeatureFlag.find(feature_flag)
    puts "❌ Feature flag '#{feature_flag}' not found in configuration"
    return
  end

  puts "✅ Feature flag '#{feature_flag}' exists in configuration"
  puts

  # Get all Flipper gates for this feature flag
  gates = Flipper::Adapters::ActiveRecord::Gate.where(feature_key: [feature_flag, "#{feature_flag}.negated"])

  puts "📊 Current Flipper Gates:"
  if gates.empty?
    puts "  No gates found - feature flag not enabled for any actors"
    return
  end

  gates.each do |gate|
    puts "  Gate: #{gate.feature_key} | Key: #{gate.key} | Value: #{gate.value}"
  end
  puts

  # Analyze actors (SecurityRoles, Users, Teams, etc.) that have this flag enabled
  enabled_actors = gates.where(feature_key: feature_flag, key: 'actors').pluck(:value)

  puts "🎭 Enabled Actors (#{enabled_actors.size}):"
  if enabled_actors.empty?
    puts "  No individual actors found"
  else
    enabled_actors.each do |actor_gid|
      begin
        actor = GlobalID.find(actor_gid)
        case actor
        when SecurityRole
          puts "  🔐 SecurityRole: #{actor.name} (Level: #{actor.level})"
        when User
          puts "  👤 User: #{actor.name} (#{actor.email}) - SecurityRole: #{actor.security_role&.name}"
        when Team
          puts "  👥 Team: #{actor.name}"
        when Permission
          puts "  ⚡ Permission: #{actor.name}"
        else
          puts "  ❓ Unknown Actor: #{actor.class.name} - #{actor.inspect}"
        end
      rescue => e
        puts "  ❌ Invalid actor GID: #{actor_gid} (#{e.message})"
      end
    end
  end
  puts

  # Find Associate Security Level specifically
  associate_roles = SecurityRole.where(name: 'Associate')
  puts "🔍 Associate Security Roles found: #{associate_roles.size}"

  associate_roles.each do |role|
    puts "  SecurityRole: #{role.name} (ID: #{role.id}, Level: #{role.level})"

    # Check if this SecurityRole has the feature flag enabled
    role_enabled = enabled_actors.any? { |gid| gid.include?("SecurityRole/#{role.id}") }
    puts "    Feature Flag Enabled: #{role_enabled ? '✅ YES' : '❌ NO'}"

    # Count users with this security role
    users_count = role.users.employed.count
    puts "    Users with this role: #{users_count}"

    if users_count > 0 && users_count <= 20
      puts "    👤 Users:"
      role.users.employed.limit(20).each do |user|
        features = Features.build(user: user)
        has_flag = features.enabled?(feature_flag)
        puts "      - #{user.name} (#{user.email}) - Flag: #{has_flag ? '✅' : '❌'}"
      end
    elsif users_count > 20
      puts "    👤 Sample of first 10 users:"
      role.users.employed.limit(10).each do |user|
        features = Features.build(user: user)
        has_flag = features.enabled?(feature_flag)
        puts "      - #{user.name} (#{user.email}) - Flag: #{has_flag ? '✅' : '❌'}"
      end
      puts "      ... and #{users_count - 10} more users"
    end
  end
  puts

  # Check for individual Associate users who might have the flag enabled directly
  puts "🔍 Individual Associate Users with Feature Flag Enabled:"
  individual_associate_users = []

  enabled_actors.each do |actor_gid|
    next unless actor_gid.include?('User/')

    begin
      user = GlobalID.find(actor_gid)
      if user.security_role&.name == 'Associate'
        individual_associate_users << user
        puts "  👤 #{user.name} (#{user.email}) - SecurityRole: #{user.security_role.name}"
      end
    rescue => e
      puts "  ❌ Error loading user from GID #{actor_gid}: #{e.message}"
    end
  end

  if individual_associate_users.empty?
    puts "  No individual Associate users found with direct feature flag access"
  end
  puts

  # Summary
  puts "📋 SUMMARY:"
  puts "  Total gates: #{gates.size}"
  puts "  Enabled actors: #{enabled_actors.size}"
  puts "  Associate SecurityRoles: #{associate_roles.size}"

  associate_roles_with_flag = associate_roles.select do |role|
    enabled_actors.any? { |gid| gid.include?("SecurityRole/#{role.id}") }
  end

  puts "  Associate SecurityRoles with flag: #{associate_roles_with_flag.size}"
  puts "  Individual Associate users with flag: #{individual_associate_users.size}"

  total_affected_associate_users = 0
  associate_roles_with_flag.each do |role|
    total_affected_associate_users += role.users.employed.count
  end
  total_affected_associate_users += individual_associate_users.size

  puts "  🎯 TOTAL Associate users affected: #{total_affected_associate_users}"
  puts

  # Return data for script generation
  {
    associate_roles_with_flag: associate_roles_with_flag,
    individual_associate_users: individual_associate_users,
    total_affected: total_affected_associate_users
  }
end

# Run the analysis
if __FILE__ == $0
  analyze_groups_messenger_flag
end
