# Vars Helper for Zipline
VARS_HELPER_VERSION = "0.1.0"

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
  puts "• so / switch_org             → Switch org"
  puts "• usc / sc                    → Unsafe/safe console modes"
  puts "• erp / drp                   → Enable/disable return printing"
end

vars_helper_version
vars_helper_cheatsheet

def init_variables
  user ||= User.employed.last
  team ||= Team.active.last
  sa ||= service_account ||= User.service_user
  hq ||= Team.find_by(id: 1)
  c ||= comm ||= communication ||= Communication.published.last
  resource ||= ResourceLibrary::Resource.last
  doc ||= ResourceLibrary::Document.last
  group ||= Discuss::Group.last
  user_context ||= UserContext.new(user, team)

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

def so
  switch_org
end

def usc
  unsafe_console!
end

def sc
  safe_console!
end

def erp
  enable_return_printing
end

def drp
  disable_return_printing
end
