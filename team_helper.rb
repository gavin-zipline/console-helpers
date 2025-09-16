TEAM_HELPER_VERSION = "0.1.7"
def team_helper_cheatsheet
  puts   "\n🚀🚀🚀 TEAM HELPER — VERSION #{TEAM_HELPER_VERSION} 🚀🚀🚀"
  puts "\n📘 Team Helper Cheatsheet:"
  puts "\n🛠 Methods:"
  puts "• find_team(param)       → Smart find a Team by ID, name, or reference number"
  puts "• teams_from_ids(ids)    → Load Teams from array of IDs; report missing"
  puts "• teams_from_reference_numbers(refs) → Load Teams from array of reference_numbers; report missing"
  puts "\n🛠 Team Instance Methods:"
  puts "• team.summary           → Key attributes including store and team type"
  puts "• team.members           → List of Users on the Team"
  puts "• team.tasks             → List of Tasks assigned to the Team"
  puts "• team.feature_flags     → List enabled Feature Flags for the Team"
end
ConsoleHelpers.register_helper("team", TEAM_HELPER_VERSION, method(:team_helper_cheatsheet))

module TeamHelper
  def find_team(param)
    case param
    when Integer
      Team.find_by(id: param)
    when String
      Team.find_by('name ILIKE ? OR reference_number = ?', "%#{param}%", param)
    else
      raise ArgumentError, "Unsupported param type: #{param.class}"
    end
  end

  def teams_from_ids(ids)
    disable_return_printing
    ids = ids.map(&:to_i)
    teams = Team.where(id: ids).to_a
    found_ids = teams.map(&:id)
    missing_ids = ids - found_ids
    if missing_ids.empty?
      puts "✅ Found all #{teams.size} teams."
    else
      puts "⚠️ Found #{teams.size} of #{ids.size} teams."
      puts "⚠️ Missing IDs: #{missing_ids.join(', ')}"
    end
    enable_return_printing
    teams
  end

  def teams_from_reference_numbers(ref_nums)
    disable_return_printing
    ref_nums = ref_nums.map(&:to_s)
    padded_ref_nums = ref_nums.map { |r| r.rjust(4, '0') }
    search_ref_nums = (ref_nums + padded_ref_nums).uniq

    teams = Team.where(reference_number: search_ref_nums).to_a
    found_refs = teams.map(&:reference_number)

    missing_refs = []
    padded_matches = []

    ref_nums.each do |ref|
      if found_refs.include?(ref)
        # Found raw
      elsif found_refs.include?(ref.rjust(4, '0'))
        padded_matches << ref
      else
        missing_refs << ref
      end
    end

    if missing_refs.empty?
      puts "✅ Found all #{teams.size} teams."
    else
      puts "⚠️ Found #{teams.size} of #{ref_nums.size} teams."
      puts "⚠️ Missing Reference Numbers: #{missing_refs.join(', ')}"
    end

    if padded_matches.any?
      puts "⚡ Note: The following reference numbers were found after padding: #{padded_matches.join(', ')}"
    end

    enable_return_printing
    teams
  end

  class ::Team
    def summary
      {
        id: id,
        reference_number: reference_number,
        name: name,
        team_type: team_type&.name,
        store_id: store_id,
        store_reference: store&.reference_number,
        created_at: created_at,
        updated_at: updated_at
      }.pretty_inspect
    end

    def members
      users
    end

    def tasks
      team_tasks
    end

    def feature_flags
      Flipper.features.select { |feature| feature.enabled?(self) }
                     .map(&:key)
                     .sort
    end

    def create_manage_user_context
      team_memberships.active_employees.managers_only.first&.to_user_context
    end
  end
end





enable_return_printing
team_helper_cheatsheet
include TeamHelper
