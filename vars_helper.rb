VARS_HELPER_VERSION = "0.1.0"
def vars_helper_cheatsheet
  puts   "\n�🚀🚀 VARS HELPER — VERSION #{VARS_HELPER_VERSION} 🚀🚀🚀"
  puts "\n�📘 Vars Helper Cheatsheet:"
  puts "\n🛠 Methods:"
  puts "• init_variables              → Initializes default objects"
  puts "• init!                       → Injects variables into the top-level binding"
  puts "• vars                        → Displays summary table of initialized variables"
  puts "• org                         → Current org shortname"
  puts "• so(\"shortname\")             → Switch org directly (paste-safe)"
  puts "• so / switch_org             → Switch org (interactive prompt)"
  puts "• usc / sc                    → Unsafe/safe console modes"
  puts "• erp / drp                   → Enable/disable return printing"
end
ConsoleHelpers.register_helper("vars", VARS_HELPER_VERSION, method(:vars_helper_cheatsheet))
disable_return_printing if defined?(disable_return_printing)
VARS_HELPER_VERSION = "0.1.0"
ConsoleHelpers.register_helper("vars", VARS_HELPER_VERSION, method(:vars_helper_cheatsheet))
# Vars Helper for Zipline

def vars_helper_version
  puts "🧭 Vars Helper Version: #{VARS_HELPER_VERSION}"
end

def vars_helper_cheatsheet
  puts   "\n🚀🚀🚀 VARS HELPER — VERSION #{VARS_HELPER_VERSION} 🚀🚀🚀"
  puts "\n📘 Vars Helper Cheatsheet:"
  puts "\n🛠 Methods:"
  puts "• init_variables              → Initializes default objects"
  puts "• init!                       → Injects variables into the top-level binding"
  puts "• vars                        → Displays summary table of initialized variables"
  puts "• org                         → Current org shortname"
  puts "• so(\"shortname\")             → Switch org directly (paste-safe)"
  puts "• so / switch_org             → Switch org (interactive prompt)"
  puts "• usc / sc                    → Unsafe/safe console modes"
  puts "• erp / drp                   → Enable/disable return printing"
end

vars_helper_version
vars_helper_cheatsheet
enable_return_printing if defined?(enable_return_printing)

def init_variables
  user = User.employed.last
  team = Team.active.last
  sa = User.service_user
  hq = Team.find_by(id: 1)
  comm = Communication.published.last
  resource = ResourceLibrary::Resource.last
  doc = ResourceLibrary::Document.last
  group = Discuss::Group.last
  user_context = UserContext.new(user, team)

  puts "✅ init_variables loaded defaults" unless defined?(Rails::Console) && !Rails.const_defined?("Console")

  {
    user: user,
    sa: sa,
    team: team,
    hq: hq,
    comm: comm,
    communication: comm,
    resource: resource,
    doc: doc,
    document: doc,
    group: group,
    user_context: user_context
  }
end

def init!
  init_variables.each do |k, v|
    unless TOPLEVEL_BINDING.local_variable_defined?(k)
      TOPLEVEL_BINDING.local_variable_set(k, v)
    end
  end
end

def vars(vars_hash = nil)
  vars_hash ||= init_variables
  rows = vars_hash.map do |k, v|
    [k, v.class.name, v.inspect.truncate(60)]
  rescue => e
    [k, 'Error', e.message]
  end

  as_a_table('Variable', 'Class', 'Preview') { rows }
end

def org
  Organization.current.shortname
end

# Switch orgs. With no argument, falls back to the interactive company helper.
# With a shortname, switches directly so the call is safe inside a pasted block
# (the interactive prompt would otherwise eat the next line of the paste).
def so(shortname = nil)
  return switch_org if shortname.nil?

  choice = shortname.to_s.strip.downcase
  return false unless handle_choice(choice)

  asciify(choice)
  true
end

def usc
  unsafe_console!
end

def sc
  safe_console!
end

def erp
  enable_return_printing if defined?(enable_return_printing)
end

def drp
  disable_return_printing if defined?(disable_return_printing)
end
