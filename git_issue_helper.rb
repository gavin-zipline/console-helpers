GIT_ISSUE_HELPER_VERSION = "0.1.0"
def git_issue_helper_cheatsheet
  puts "\n📘 Git Issue Helper Cheatsheet:"
  puts "• Add your git issue helper methods here."
end
ConsoleHelpers.register_helper("git_issue", GIT_ISSUE_HELPER_VERSION, method(:git_issue_helper_cheatsheet))
# Git Issue Helper Script
GIT_ISSUE_HELPER_VERSION = "1.3.9"

def git_issue_helper_version
  puts "🧭 Git Issue Helper Version: #{GIT_ISSUE_HELPER_VERSION}"
  GIT_ISSUE_HELPER_VERSION
end
# Provides interactive GitHub issue tools for triage, prioritization, and analysis in the Heroku console.

USER_DIRECTORY = {
  "ZiplineAdmin"     => { name: "System", team: "Automation", p: 3 },

  "abbyj24"          => { name: "Abby", team: "AM", p: 2 },
  "adaphill"         => { name: "Adam P", team: "AM", p: 2 },
  "ashleyHall21"     => { name: "Ashley", team: "AM", p: 2 },
  "chrismadd123"     => { name: "Chris M", team: "AM", p: 2 },
  "constancefv"      => { name: "Coco", team: "AM", p: 2 },
  "1zabelle"         => { name: "Isabelle", team: "AM", p: 2 },
  "katiemarks"       => { name: "Katie", team: "AM", p: 2 },
  "llavere"          => { name: "Leanne", team: "AM", p: 2 },
  "nicolefiasco"     => { name: "Nicole F", team: "AM", p: 2 },
  "nicolemaroutsos"  => { name: "Nicole M", team: "AM", p: 2 },
  "nathantthompson"  => { name: "Nathan", team: "AM", p: 2 },

  "AmeenaK-P"        => { name: "Ameena", team: "Tier-1", p: 3 },
  "AmyMajewski"      => { name: "Amy", team: "Tier-1", p: 3 },
  "ZiplineChelsea"   => { name: "Chelsea", team: "Tier-1", p: 1 },
  "D-Soco"           => { name: "D", team: "Tier-1", p: 3 },
  "KarolyNemeth"     => { name: "Charlie", team: "Tier-1", p: 3 },
  "jessicaophoff"    => { name: "Jessica", team: "Tier-1", p: 3 },
  "ZipKristal"       => { name: "Kristal", team: "Tier-1", p: 3 },
  "robmurrah"        => { name: "Rob", team: "Tier-1", p: 3 },

  "pablitozip"       => { name: "Pablo", team: "Tier-2", p: 3 },
  "gavin-zipline"    => { name: "Gavin", team: "Tier-2", p: 3 },
  "Kam-Zipline"      => { name: "Kamran", team: "Tier-2", p: 3 },

  "richardtru"       => { name: "Rich T", team: "Tier-3", p: 1 },
  "hicran"           => { name: "Hicran", team: "Tier-3", p: 3 },
  "alisonmtague"     => { name: "Alison", team: "Tier-3", p: 3 },
  "NickBri"          => { name: "Nick", team: "Tier-3", p: 3 },
  "Topleftstyll"     => { name: "Josh", team: "Tier-3", p: 3 },
  "SimonGRoze"       => { name: "Simon", team: "Tier-3", p: 3 },
  "zipline-dave"     => { name: "Dave", team: "E&E", p: 1 },
  "richgardos"       => { name: "Rich", team: "Management", p: 3 },
  "ChrisGallo"       => { name: "Chris G", team: "AM", p: 1 },
  "KylaMcGowan"      => { name: "Kyla", team: "E&E", p: 1 },
  "tkz79"           => { name: "Tom", team: "Engineering", p: 3 }
}

VALID_LABELS = [
  "activate-enhancements", "auto:archive-comms", "auto:oreilly-skip", "bug", "bug:editor:bullet-copy", "bug:editor:persistent-formatting", "bulk-update", "c:24hourfitness", "c:7eleven", "c:aeo", "c:aeointernational", "c:aeotest", "c:allbirds", "c:alo", "c:alotest", "c:americascarmart", "c:arcteryx", "c:aritzia", "c:asi", "c:athleta", "c:athletatest", "c:away", "c:bananarepublic", "c:bananarepublicjp", "c:bargainhunt", "c:bbby", "c:bbw", "c:bbwtest", "c:beallsinc", "c:bedrock", "c:belletire", "c:bevmo", "c:big5", "c:blains", "c:bncollege", "c:busybeaver", "c:casper", "c:chosenforever", "c:cititrends", "c:coachna", "c:coachnatest", "c:cobalt", "c:colehaan", "c:community", "c:connect5", "c:containerstore", "c:cookies", "c:cookiesca", "c:cottonon", "c:countrysupplier", "c:credobeauty", "c:crocs", "c:crocseu", "c:cvp", "c:cvs", "c:cvstest", "c:dbsupply", "c:dgpb", "c:doordash", "c:eetest", "c:festfoods", "c:ffh", "c:ffhtest", "c:fjallraven", "c:fjallravendemo", "c:formanmills", "c:framebridge", "c:gap", "c:gapcn", "c:gapjp", "c:gratis", "c:gtigrows", "c:guccipoc", "c:guitarcenter", "c:hearusa", "c:helzberg", "c:holistic", "c:hollywoodfeed", "c:hyvee", "c:insa", "c:intermix", "c:janieandjack", "c:jcrewgroup", "c:juguetron", "c:juguetrontest", "c:kavehome", "c:ksna", "c:ksp", "c:laurasecord", "c:lbr", "c:lbrtest", "c:lego", "c:legodemo", "c:lindorawellness", "c:llbean", "c:llflooring", "c:lululemon", "c:lululemonasia", "c:lululemonaunz", "c:lululemonchina", "c:lululemonemea", "c:lululemontest", "c:marks", "c:markstest", "c:maurices", "c:mco", "c:mizzenandmain", "c:nike", "c:nikedev", "c:northerntool", "c:nysc", "c:oldnavy", "c:oreillyauto", "c:oreillyautotest", "c:pacsun", "c:parachutehome", "c:parallel", "c:partsource", "c:pharmacann", "c:pinkbubble", "c:quiktrip", "c:rallyhouse", "c:rexall", "c:rhone", "c:riteaid", "c:riteaiddemo", "c:riteaidtest", "c:rockler", "c:rona", "c:rothys", "c:rrs", "c:rubino", "c:russellcellular", "c:sephora", "c:sephoraconnect", "c:sephoraconnectdev", "c:sephorademo", "c:sephorapoc", "c:sev", "c:skechers", "c:skinlaundry", "c:speedway", "c:spencers", "c:sportchek", "c:sportchektest", "c:staplesretail", "c:staplesretailtest", "c:stateandliberty", "c:sunshineworkbench", "c:sweetflower", "c:tecovas", "c:tfm", "c:thegoodguys", "c:theory", "c:theparentco", "c:thriftgiant", "c:tillys", "c:torrid", "c:travismathew", "c:trr", "c:truesociety", "c:uncleg", "c:uniqlona", "c:uniqlonatest", "c:vineyardvines", "c:visionworks", "c:warbyparker", "c:warbyparkerdemo", "c:warbyparkertest", "c:wg", "c:woodhouse", "c:worldmarket", "c:zipline", "c:ziplineeu", "cse-standup", "cycle-bleed", "cycle:atlas", "cycle:ava", "cycle:blossom", "cycle:dragon", "cycle:fiona", "cycle:frost", "cycle:hops", "cycle:lucky", "cycle:mittens", "cycle:raphael", "cycle:roar", "cycle:sol", "cycle:solstice", "cycle:sprout", "cycle:tails", "cycle:twilight", "cycle:ziphero", "dbt", "design:in-progress", "design:needed", "design:ready", "design:triage", "do-not-merge", "documentation-needed", "enablement", "feat:address-book", "feat:admin", "feat:alignment", "feat:android", "feat:api", "feat:archive-message", "feat:assessments", "feat:associate-experience", "feat:attachments", "feat:audits", "feat:autosave", "feat:bookmarks", "feat:branch-reports", "feat:bulletin", "feat:calendar", "feat:categories", "feat:clock geolocation", "feat:clock-control", "feat:communication", "feat:copy-site", "feat:custom-reports", "feat:daily-digest", "feat:dashboard", "feat:data-importer", "feat:data-snapshot", "feat:dayforce-widget", "feat:daysheet", "feat:decommission-site", "feat:departments", "feat:distribution", "feat:editor", "feat:email", "feat:feature-flag", "feat:field-publishing", "feat:file-previews", "feat:filters", "feat:focused-publisher-view", "feat:follow-up-actions", "feat:forms", "feat:froala", "feat:groups", "feat:help-forums", "feat:highlights", "feat:hub", "feat:insights", "feat:integration:dayforce", "feat:integration:docebo", "feat:integration:kronos", "feat:integration:outlook", "feat:integration:ukg", "feat:intercom", "feat:ios", "feat:kb-articles", "feat:learning", "feat:library-sync", "feat:lms", "feat:location", "feat:login", "feat:mail-merge", "feat:message-progress-report", "feat:messenger", "feat:mth", "feat:my-team", "feat:notice", "feat:notifications", "feat:ops-dashboard", "feat:organization-roles", "feat:other", "feat:photo-tasks", "feat:pipelines", "feat:policies", "feat:print", "feat:reactions", "feat:recurring-messages", "feat:report", "feat:report-builder", "feat:reporting", "feat:resource-generator", "feat:resource-library", "feat:saml", "feat:scorm", "feat:search", "feat:securitylevel", "feat:settings", "feat:share-message", "feat:shift-changes", "feat:spotlight-message", "feat:survey", "feat:survey-task", "feat:task-approval", "feat:task-comments", "feat:task-nudge", "feat:task-prioritization", "feat:tasks", "feat:team-performance-widget", "feat:team-role", "feat:teams", "feat:test-site", "feat:time-task-estimate", "feat:timesheets", "feat:tours", "feat:translation", "feat:video", "feat:view-as", "feat:widget", "feat:workflow", "feat:zippy", "flaky-tests", "help-needed", "implementation", "improvement", "integration", "intercom-ticket", "internal", "invalid", "investigation", "kanban", "lurns-topic-cse", "most-wanted:am", "most-wanted:cse", "most-wanted:tier-1", "needs-shaping", "needs-validation", "offboarding", "operations", "p1", "p2", "p3", "p:AM:abby", "p:AM:adam", "p:AM:amy", "p:AM:ashley", "p:AM:chrismaddern", "p:AM:constance", "p:AM:corbin", "p:AM:dave", "p:AM:isabelle", "p:AM:katie", "p:AM:leanne", "p:AM:nathan", "p:AM:nicolefiasco", "p:AM:nicolemaroutsos", "p:zipresponse", "product-escalation", "recurring", "security", "self-service:beta", "stale", "t-size:large", "t-size:medium", "t-size:small", "t-size:x-large", "team:activate", "team:data", "team:design", "team:extend", "team:mobile", "team:operate", "team:perform", "team:platformers", "team:tier1", "team:tier2", "team:tier3", "tech-freeze", "tmp-baires-dev", "triage", "wont-fix"
]

FEATURE_LABEL_PREFIX = "feat:"


module GitHubClient
  OWNER = "retailzipline"
  REPO  = "customer-support"
  TOKEN = ENV["GITHUB_TOKEN"]

  def self.issue_url(issue_number = nil)
    base = "https://api.github.com/repos/#{OWNER}/#{REPO}/issues"
    issue_number ? "#{base}/#{issue_number}" : base
  end

  def self.auth_headers
    raise "Missing GitHub token" unless TOKEN
    {
      "Authorization" => "token #{TOKEN}",
      "User-Agent" => "Rails Console"
    }
  end

  def self.get(url)
    uri = URI(url)
    req = Net::HTTP::Get.new(uri)
    auth_headers.each { |k, v| req[k] = v }
    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(req) }
  end

  def self.graphql(query)
    uri = URI("https://api.github.com/graphql")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    request = Net::HTTP::Post.new(uri.path, {
      "Authorization" => "Bearer #{TOKEN}",
      "Content-Type" => "application/json",
      "User-Agent" => "Rails Console"
    })
    request.body = { query: query }.to_json

    http.request(request)
  end

  def self.fetch_labels
    all_labels = []
    page = 1

    loop do
      url = "https://api.github.com/repos/#{OWNER}/#{REPO}/labels?per_page=100&page=#{page}"
      res = get(url)
      page_labels = JSON.parse(res.body)

      break if page_labels.empty?

      all_labels += page_labels
      page += 1
    end

    all_labels.map { |l| l["name"] }.uniq.sort
  end
end

def audit_label_usage
  repo_labels = GitHubClient.fetch_labels
  missing = VALID_STATUSES - repo_labels
  extra = repo_labels - VALID_STATUSES

  puts "\n🧪 Label Audit Report:"
  puts "- Missing from GitHub: #{missing.any? ? missing.join(', ') : 'none'}"
  puts "- Present in GitHub but not in VALID_STATUSES: #{extra.any? ? extra.join(', ') : 'none'}"
end

def valid_label?(label)
  GitHubClient.fetch_labels.include?(label)
end
class GitIssue
  attr_reader :raw, :number, :title, :created_at, :labels, :reporter, :status, :state
  @@all = []

  def self.all
    @@all
  end

  def self.reset!
    @@all = []
  end

  def initialize(data, status: nil)    @raw = data
    @number = data['number']
    @title = data['title']
    @created_at = Date.parse(data['created_at'])
    @labels = data['labels'].map { |l| l['name'].downcase }
    @reporter = data['user']['login']
    @state = data['state']
    @status = status
    @@all << self
  end

  def age_days
    (Date.today - created_at).to_i
  end

  def priority_label_score
    return 3 if labels.include?("priority: high")
    return 2 if labels.include?("priority: medium")
    1
  end

  def user_priority
    USER_DIRECTORY.dig(reporter, :p) || 3
  end

  def avoid?(avoid_labels)
    labels.any? { |l| avoid_labels.include?(l) }
  end

  def url
    "https://github.com/retailzipline/customer-support/issues/#{number}"
  end

  def to_s
    "##{number}: #{title} (#{reporter})"
  end

  def scheduled_and_due_today_or_later?
    labels.include?("scheduled") && title =~ /\b\d{4}-\d{2}-\d{2}\b/ && Date.parse(title[/\b\d{4}-\d{2}-\d{2}\b/]) >= Date.today
  rescue
    false
  end
end

# age_bucket
# Purpose: Return a readable string that buckets issue age into predefined ranges.
def age_bucket(days_old)
  case days_old
  when 0..2 then '0–2d'
  when 3..7 then '3–7d'
  when 8..14 then '8–14d'
  when 15..30 then '15–30d'
  else '>30d'
  end
end

# get_git_issue
# Purpose: Show full context for a single GitHub issue, including body, comments, and involved users.
# Returns a hash with :issue and :comments. If include_timeline: true, also includes :timeline.
def get_git_issue(issue_number, include_timeline: false)
  issue = JSON.parse(GitHubClient.get(GitHubClient.issue_url(issue_number)).body)

  comments = JSON.parse(GitHubClient.get("#{GitHubClient.issue_url(issue_number)}/comments").body)

  result = { issue: issue, comments: comments }

  if include_timeline
    timeline_url = "https://api.github.com/repos/#{GitHubClient::OWNER}/#{GitHubClient::REPO}/issues/#{issue_number}/timeline"
    timeline = JSON.parse(GitHubClient.get(timeline_url).body)
    result[:timeline] = timeline
  end

  result
end

# get_git_issues
# Purpose: Fetch Tier-2 issues from GitHub and group/filter them based on input params.
# Supports filters: state, assignee, statuses, label, require_tier2
# Grouping options: :feature, :customer, :reporter, :reporter_team, :age
# Returns GitIssue.all after populating.
def get_git_issues(state: "open", assignee: "none", statuses: ["triage", "selected_for_work", "in_progress"], label: nil, grouping: :feature, created: nil, require_tier2: true)
  require 'date'

  res = GitHubClient.get("#{GitHubClient.issue_url}?state=#{state}&per_page=100")
  issues = JSON.parse(res.body)
  # Validate labels against known GitHub labels
  valid_labels = GitHubClient.fetch_labels
  issues.each do |issue|
    issue['labels'].each do |l|
      # puts "⚠️ Unknown label: #{l['name']}" unless valid_labels.include?(l['name'])
    end
  end

  tier2_issues = issues.select do |issue|
    (!require_tier2 || issue['labels'].any? { |l| l['name'].downcase.match?(/(^|:)tier2$/) }) &&
    (assignee == "none" || issue.dig('assignee', 'login') == assignee) &&
    (label.nil? || issue['labels'].any? { |l| l['name'].casecmp(label.to_s).zero? }) &&
    case created
    when :today
      Date.parse(issue['created_at']) == Date.today
    when :this_week
      (Date.today - Date.parse(issue['created_at'])).to_i <= 7
    when :this_month
      (Date.today - Date.parse(issue['created_at'])).to_i <= 30
    else
      true
    end
  end

  GitIssue.reset!
  tier2_issues.each { |data| GitIssue.new(data) }

  # No printing; just return the GitIssue.all for further use if desired
  GitIssue.all
end

# next_issue
# Purpose: Recommend the next best GitHub issue to work next.
# Logic: Scores each issue based on priority label, age, reporter match, and user priority.
# Prints top 3 ranked issues to console. Returns the top-ranked issue object.
def next_issue(state: "open", statuses: ["triage", "selected_for_work", "in_progress"], preferred_reporters: [], avoid_labels: [], created: nil, weights: {}, boost_labels: {})
  disable_return_printing
  issues = GitIssue.all

  issues = issues.select do |issue|
    case created
    when :today
      issue.created_at == Date.today
    when :this_week
      (Date.today - issue.created_at).to_i <= 7
    when :this_month
      (Date.today - issue.created_at).to_i <= 30
    else
      true
    end
  end

  default_weights = {
    priority_label: 2,
    age: 0.5,
    user_priority: 1,
    reporter_bonus: 2,
    label_boost: 1
  }
  weights = default_weights.merge(weights)

  ranked = issues.map do |issue|
    score = (issue.priority_label_score * weights[:priority_label]) +
            (issue.age_days * weights[:age]) +
            ((3 - issue.user_priority) * weights[:user_priority]) +
            (preferred_reporters.include?(issue.reporter) ? weights[:reporter_bonus] : 0)
    score += 5 if issue.scheduled_and_due_today_or_later?
    score += 5 if issue.labels.include?("p1")
    score += 5 if issue.labels.include?("feat:alignment")

    label_boost_total = issue.labels.sum { |l| boost_labels[l] || 0 }
    score += (label_boost_total * weights[:label_boost])
    score -= 100 if issue.avoid?(avoid_labels)

    [issue, score]
  end

  top_three = ranked.sort_by { |_, score| -score }.first(3)

  puts "\n🧭 Top 3 Ranked Issues to Work On Next:"
  top_three.each_with_index do |(issue, score), i|
    rank = %w[🥇 🥈 🥉][i] || "#{i + 1}."
    puts "\n#{rank} #{issue}"
    puts "   URL: #{issue.url}"
    puts "   Reporter: #{issue.reporter}"
    puts "   Score: #{score.round(2)}"
  end
  enable_return_printing
  top_three.first&.first
end

def get_project_issues_with_status(desired_status: "Triage")
  query = <<-GRAPHQL
    {
      organization(login: "retailzipline") {
        projectV2(number: 6) {
          items(first: 100) {
            nodes {
              content {
                ... on Issue {
                  number
                  title
                  state
                  labels(first: 20) {
                    nodes {
                      name
                    }
                  }
                  url
                }
              }
              fieldValues(first: 20) {
                nodes {
                  ... on ProjectV2ItemFieldSingleSelectValue {
                    field {
                      ... on ProjectV2SingleSelectField {
                        name
                      }
                    }
                    name
                  }
                }
              }
            }
          }
        }
      }
    }
  GRAPHQL

  res = GitHubClient.graphql(query)
  data = JSON.parse(res.body)
  puts "\n📦 Raw GraphQL data (truncated):"
  puts JSON.pretty_generate(data)[0..1000]  # Just the first 1000 chars
  issues = []

  items = data.dig("data", "organization", "projectV2", "items", "nodes") || []

  items.each do |item|
    content = item["content"]
    next unless content && content["number"]

    status = item["fieldValues"]["nodes"]
               .find { |n| n.dig("field", "name") == "Status" }
               &.dig("name")
    status&.strip!

    puts "📌 ##{content['number']} raw status: #{status.inspect}"
    puts "🔍 Comparing: #{status.inspect} vs #{desired_status.to_s.strip.inspect}"

    if status.to_s.strip.downcase == desired_status.to_s.strip.downcase
      puts "✅ Including ##{content['number']}"
      issues << {
        number: content["number"],
        title: content["title"],
        state: content["state"],
        labels: content["labels"]["nodes"].map { |l| l["name"] },
        url: content["url"]
      }
    else
      puts "🚫 Skipping ##{content['number']} due to status mismatch"
    end
  end

  issues.each do |issue|
    puts "##{issue[:number]} - #{issue[:title]} (#{issue[:state]})"
    puts "Labels: #{issue[:labels].join(', ')}"
    puts "URL: #{issue[:url]}"
    puts "-" * 60
  end

  puts "\n🧾 All statuses seen:"
  puts items.map { |item|
    item["fieldValues"]["nodes"]
      .find { |n| n.dig("field", "name") == "Status" }
      &.dig("name")
  }.compact.uniq.sort

  issues
end

# get_issue_comments
# Purpose: Fetch and print all comments for a given GitHub issue number.
# Prints each comment with index and metadata. Returns array of comment hashes.
def get_issue_comments(issue_number)
  res = GitHubClient.get("#{GitHubClient.issue_url(issue_number)}/comments")
  comments = JSON.parse(res.body)

  puts "\n💬 Comments for Issue ##{issue_number} (#{comments.size} total):"
  comments.each_with_index do |c, i|
    puts "\n--- Comment ##{i + 1} ---"
    puts "👤 #{c['user']['login']} on #{c['created_at']}"
    puts c['body']
  end

  comments
end


def git_issue_cheatsheet
  puts   "\n🚀🚀🚀 GIT ISSUE HELPER — VERSION #{GIT_ISSUE_HELPER_VERSION} 🚀🚀🚀"
  puts "\n📘 Git Issue Helper Cheatsheet:"
  puts "• get_git_issue(issue_number, include_timeline: false)"
  puts "  → Returns a hash with :issue and :comments. Use include_timeline: true to also return :timeline. Does not print."
  puts ""
  puts "• get_issue_comments(issue_number)"
  puts "  → Fetches and prints all comments for a given GitHub issue number."
  puts "  Returns an array of comment hashes."
  puts ""
  puts "• get_git_issues(...)"
  puts "  → Fetches and filters GitHub issues using several parameters. Returns an array of GitIssue objects. Does not print."
  puts "    Parameters:"
  puts "      - state: 'open', 'closed', or 'all' (default: 'open')"
  puts "      - assignee: GitHub login or 'none' (default: 'none')"
  puts "      - label: string or nil"
  puts "      - created: :today, :this_week, :this_month (optional)"
  puts "      - grouping: :feature, :customer, :reporter, :reporter_team, :age"
  puts ""
  puts "• triage_my_on_holds"
  puts "  → Returns open issues labeled 'On Hold' and assigned to you where someone else commented after the hold was applied."
  puts ""
  puts "• next_issue(...)"
  puts "  → Suggests the next GitHub issue to work on, ranked by weighted scoring across labels, reporter priority, and age."
  puts ""
  puts "• get_project_issues_with_status(desired_status: 'Triage')"
  puts "  → Queries GitHub Projects v2 using GraphQL to fetch issues with a matching status. Prints summaries."
  puts ""
  puts "• git_issue_helper_version"
  puts "  → Prints the current helper version."
  puts ""
  puts "• git_issue_cheatsheet"
  puts "  → Show this cheatsheet again."
  puts ""
end


def triage_my_on_holds
  disable_return_printing
  my_login = 'gavin-zipline'
  on_hold_issues = get_git_issues(state: "open", assignee: my_login, label: "On Hold", grouping: :reporter)

  triage_needed = []

  on_hold_issues_data = GitIssue.all.select { |i| i.labels.include?("on hold") && i.state == "open" }

  on_hold_issues_data.each do |issue|
    data = get_git_issue(issue.number, include_timeline: true)
    timeline = data[:timeline]
    hold_event = timeline.find { |event| event['event'] == 'labeled' && event.dig('label', 'name') == 'On Hold' }
    next unless hold_event
    hold_time = Time.parse(hold_event['created_at'])

    comments = data[:comments]

    next unless comments.any? do |c|
      comment_time = Time.parse(c['created_at'])
      comment_user = c['user']['login']
      comment_time > hold_time &&
        comment_user != my_login &&
        (!defined?(SYSTEM_USERS) || !SYSTEM_USERS.include?(comment_user))
    end

    triage_needed << issue
  end

  puts "\n🛎️  Issues to triage (activity after On Hold):"
  triage_needed.each do |i|
    puts "##{i.number}: #{i.title} — #{i.url}"
  end

  enable_return_printing
  triage_needed
end

git_issue_cheatsheet

#
# get_issue_metadata
# Purpose: Fetch basic metadata for a given issue number, pulling directly from the get_git_issue result.
def get_issue_metadata(issue_number)
  issue = get_git_issue(issue_number)[:issue]
  {
    number: issue["number"],
    title: issue["title"],
    state: issue["state"],
    assignee: issue["assignee"]&.dig("login"),
    labels: issue["labels"]&.map { |l| l["name"] },
    created_at: issue["created_at"],
    updated_at: issue["updated_at"],
    closed_at: issue["closed_at"],
    comments: issue["comments"]
  }
end


# get_issue_status
# Purpose: Fetch the status of an issue from GitHub Projects v2 via GraphQL using the issue node ID.
def get_issue_status(issue_node_id)
  query = <<~GRAPHQL
    query($id: ID!) {
      node(id: $id) {
        ... on Issue {
          projectItems(first: 10) {
            nodes {
              project {
                title
              }
              fieldValues(first: 20) {
                nodes {
                  __typename
                  ... on ProjectV2ItemFieldSingleSelectValue {
                    name
                    field {
                      ... on ProjectV2FieldCommon {
                        name
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  GRAPHQL

  result = github_graphql(query, { id: issue_node_id })
  nodes = result.dig("data", "node", "projectItems", "nodes")
  return nil unless nodes && nodes.any?

  nodes.each_with_index do |item_node, i|
    project_title = item_node.dig("project", "title") || "Unknown Project"
    puts "\n📦 Project Item ##{i + 1} — #{project_title}:"
    fields = item_node.dig("fieldValues", "nodes") || []
    fields.each do |field|
      field_type = field["__typename"]
      if field_type == "ProjectV2ItemFieldSingleSelectValue"
        field_name = field.dig("field", "name")
        field_value = field["name"]
        puts "📝 #{field_name}: #{field_value}"
      else
        keys = field.keys - ["__typename"]
        keys.each do |k|
          puts "🔹 #{field_type} - #{k}: #{field[k].inspect}"
        end
      end
    end
  end

  # Look for status in any project item
  nodes.each do |item_node|
    fields = item_node.dig("fieldValues", "nodes") || []
    status_node = fields.find do |f|
      f["__typename"] == "ProjectV2ItemFieldSingleSelectValue" &&
        f.dig("field", "name")&.strip&.casecmp("status") == 0
    end
    return status_node["name"] if status_node
  end

  nil
end

# github_graphql
# Purpose: Call GitHub's GraphQL API with the given query and variables.
require 'net/http'
require 'uri'
require 'json'
def github_graphql(query, variables = {})
  uri = URI.parse("https://api.github.com/graphql")
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Post.new(uri.request_uri)
  request["Authorization"] = "Bearer #{ENV['GITHUB_PAT']}"
  request["Content-Type"] = "application/json"
  request.body = { query: query, variables: variables }.to_json

  response = http.request(request)
  JSON.parse(response.body)
end
