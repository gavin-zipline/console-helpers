SMART_QUERY_HELPER_VERSION = "0.1.0"
def smart_query_helper_cheatsheet
  puts "\n📘 Smart Query Helper Cheatsheet:"
  puts "• Add your smart query helper methods here."
end
ConsoleHelpers.register_helper("smart_query", SMART_QUERY_HELPER_VERSION, method(:smart_query_helper_cheatsheet))
# ------------------------------------------------------------------------------
# SmartQuery Helper
# ------------------------------------------------------------------------------

SMART_QUERY_HELPER_VERSION = "0.1.0"

# --------------------------------- shortcuts -------------------------------- #
def sq
  SmartQuery
end

def smart_query_helper_version
  puts "🔍 SmartQuery Helper Version: #{SMART_QUERY_HELPER_VERSION}"
  SMART_QUERY_HELPER_VERSION
end

# ------------------------------------------------------------------------------
# SmartQuery Extensions for better debugging and exploration
# ------------------------------------------------------------------------------
class SmartQuery::Query
  def summary
    <<~SUMMARY
      ┏━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┓
      ┃         SMARTQUERY SUMMARY           ┃
      ┗━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━┛

      Model:       #{scope.model.name}
      Base Scope:  #{scope.to_sql.truncate(100)}
      Rules Count: #{rules.size}

      ── RULES ────────────────────────────────
      #{pretty_rules(rules)}

      ── GENERATED SQL ────────────────────────
      #{result.to_sql}

      ── RESULT COUNT ─────────────────────────
      #{result.count} records
    SUMMARY
  end

  def explain
    puts summary
    puts "\n── EXECUTION PLAN ──────────────────────"
    puts result.explain
  end

  def sample(limit = 5)
    puts "🔍 Sample Results (first #{limit}):"
    result.limit(limit).each_with_index do |record, i|
      puts "#{i + 1}. #{record.class.name} #{record.id}: #{record.try(:name) || record.try(:title) || record.to_s}"
    end
  end

  private

  def pretty_rules(rules)
    rules.map.with_index(1) do |rule, i|
      if rule.is_a?(Hash)
        conditions = rule['c'] || rule[:c] || []
        conditions_str = conditions.map { |c| format_condition(c) }.join(' AND ')
        "#{i}. [#{conditions_str}]"
      else
        "#{i}. #{rule.to_json}"
      end
    end.join("\n")
  end

  def format_condition(condition)
    attr = condition['a'] || condition[:a]
    predicate = condition['p'] || condition[:p]
    value = condition['v'] || condition[:v]
    scope_name = condition['s'] || condition[:s]

    if scope_name
      "#{scope_name}(#{value})"
    else
      "#{attr} #{predicate} #{value.inspect}"
    end
  end
end

# ------------------------------------------------------------------------------
# SmartQuery Rule Builder - helps construct rules interactively
# ------------------------------------------------------------------------------
class SmartQueryRuleBuilder
  attr_reader :rules

  def initialize
    @rules = []
  end

  def where(attribute, predicate, value)
    @rules << { c: [{ a: attribute, p: predicate, v: value }] }
    self
  end

  def and_where(attribute, predicate, value)
    if @rules.empty?
      where(attribute, predicate, value)
    else
      @rules.last[:c] << { a: attribute, p: predicate, v: value }
    end
    self
  end

  def or_where(attribute, predicate, value)
    @rules << { c: [{ a: attribute, p: predicate, v: value }] }
    self
  end

  def scope(scope_name, value)
    @rules << { c: [{ s: scope_name, v: value }] }
    self
  end

  def and_scope(scope_name, value)
    if @rules.empty?
      scope(scope_name, value)
    else
      @rules.last[:c] << { s: scope_name, v: value }
    end
    self
  end

  def build
    @rules
  end

  def test_on(model_class)
    SmartQuery::Query.new(model_class, @rules)
  end

  def to_json(*args)
    @rules.to_json(*args)
  end
end

def build_smart_query(&block)
  builder = SmartQueryRuleBuilder.new
  builder.instance_eval(&block) if block_given?
  builder
end

# ------------------------------------------------------------------------------
# SmartQuery Documentation and Examples
# ------------------------------------------------------------------------------
def smart_query_cheatsheet
  puts "\n🔍🔍🔍 SMARTQUERY HELPER — VERSION #{SMART_QUERY_HELPER_VERSION} 🔍🔍🔍"
  puts "\n📘 SmartQuery Cheatsheet:"

  puts "\n🔍 Query Analysis:"
  puts "• query = SmartQuery::Query.new(Team, rules)"
  puts "• query.summary        → Full analysis with rules, SQL, and count"
  puts "• query.explain        → Shows execution plan and query analysis"
  puts "• query.sample(5)      → Shows first 5 results with basic info"

  puts "\n🏗️  Rule Builder:"
  puts "• builder = SmartQueryRuleBuilder.new"
  puts "• builder.where('name', 'eq', 'Store')          → Basic condition"
  puts "• builder.and_where('active', 'eq', true)       → Add AND condition"
  puts "• builder.or_where('team_type.name', 'eq', 'DC') → Add OR group"
  puts "• builder.scope('active', nil)                  → Use model scope"
  puts "• builder.test_on(Team)                         → Test the query"

  puts "\n📝 Rule Structure:"
  puts "• Basic rule: { c: [{ a: 'attribute', p: 'predicate', v: 'value' }] }"
  puts "• Scope rule: { c: [{ s: 'scope_name', v: 'value' }] }"
  puts "• Multiple conditions in same rule = AND"
  puts "• Multiple rules = OR"

  puts "\n🔧 Common Predicates:"
  puts "• 'eq'    → equals"
  puts "• 'ne'    → not equals"
  puts "• 'in'    → in array"
  puts "• 'nin'   → not in array"
  puts "• 'like'  → SQL LIKE (use % wildcards)"
  puts "• 'gt'    → greater than"
  puts "• 'gte'   → greater than or equal"
  puts "• 'lt'    → less than"
  puts "• 'lte'   → less than or equal"
  puts "• 'null'  → is null (value ignored)"
  puts "• 'nnull' → is not null (value ignored)"

  puts "\n🎯 Examples:"
  puts "• Active stores:"
  puts "  [{ c: [{ a: 'active', p: 'eq', v: true }, { a: 'team_type.name', p: 'eq', v: 'Store' }] }]"

  puts "\n• Stores OR DCs:"
  puts "  [{ c: [{ a: 'team_type.name', p: 'eq', v: 'Store' }] },"
  puts "   { c: [{ a: 'team_type.name', p: 'eq', v: 'DC' }] }]"

  puts "\n• Using scopes:"
  puts "  [{ c: [{ s: 'active', v: nil }] }]"

  puts "\n• Nested attributes:"
  puts "  [{ c: [{ a: 'metadata.STORE_TYPE', p: 'eq', v: 'Premium' }] }]"

  puts "\n💡 Shortcuts:"
  puts "• sq = SmartQuery"
  puts "• build_smart_query { where('name', 'eq', 'Test') }.test_on(Team)"
end

# ------------------------------------------------------------------------------
# Interactive SmartQuery Testing
# ------------------------------------------------------------------------------
def test_smart_query(model_class, rules)
  puts "🔍 Testing SmartQuery on #{model_class.name}..."

  query = SmartQuery::Query.new(model_class, rules)
  puts query.summary

  puts "\n📊 Sample Results:"
  query.sample(3)

  query
rescue => e
  puts "❌ Error: #{e.message}"
  puts "   Rules: #{rules.to_json}"
  nil
end

def explore_model_attributes(model_class, sample_size = 5)
  puts "🔍 Exploring #{model_class.name} attributes..."

  sample = model_class.limit(sample_size)

  puts "\n📊 Sample Records:"
  sample.each_with_index do |record, i|
    puts "#{i + 1}. ID: #{record.id}"
    puts "   Basic: #{record.try(:name) || record.try(:title) || 'N/A'}"

    if record.respond_to?(:metadata) && record.metadata.present?
      puts "   Metadata: #{record.metadata.keys.first(3).join(', ')}#{record.metadata.keys.size > 3 ? '...' : ''}"
    end

    # Show some common associations
    %w[team_type user parent].each do |assoc|
      if record.respond_to?(assoc) && record.send(assoc).present?
        assoc_obj = record.send(assoc)
        name = assoc_obj.try(:name) || assoc_obj.try(:title) || assoc_obj.id
        puts "   #{assoc.humanize}: #{name}"
      end
    end
    puts ""
  end

  puts "📋 Available Columns:"
  puts model_class.column_names.join(', ')

  puts "\n🔗 Associations:"
  puts model_class.reflect_on_all_associations.map(&:name).join(', ')
end

# ------------------------------------------------------------------------------
# SmartQuery Validator - helps debug rule issues
# ------------------------------------------------------------------------------
class SmartQueryValidator
  def self.validate_rules(rules)
    errors = []

    unless rules.is_a?(Array)
      errors << "Rules must be an array"
      return errors
    end

    rules.each_with_index do |rule, rule_index|
      unless rule.is_a?(Hash)
        errors << "Rule #{rule_index + 1}: must be a hash"
        next
      end

      conditions = rule['c'] || rule[:c]
      unless conditions.is_a?(Array)
        errors << "Rule #{rule_index + 1}: must have 'c' key with array value"
        next
      end

      conditions.each_with_index do |condition, cond_index|
        validate_condition(condition, rule_index + 1, cond_index + 1, errors)
      end
    end

    errors
  end

  class << self
    private

    def validate_condition(condition, rule_num, cond_num, errors)
      unless condition.is_a?(Hash)
        errors << "Rule #{rule_num}, Condition #{cond_num}: must be a hash"
        return
      end

      has_attr = condition.key?('a') || condition.key?(:a)
      has_scope = condition.key?('s') || condition.key?(:s)

      unless has_attr || has_scope
        errors << "Rule #{rule_num}, Condition #{cond_num}: must have either 'a' (attribute) or 's' (scope)"
        return
      end

      if has_attr && has_scope
        errors << "Rule #{rule_num}, Condition #{cond_num}: cannot have both 'a' and 's'"
        return
      end

      if has_attr
        predicate = condition['p'] || condition[:p]
        unless predicate
          errors << "Rule #{rule_num}, Condition #{cond_num}: attribute conditions must have 'p' (predicate)"
        end

        valid_predicates = %w[eq ne in nin like gt gte lt lte null nnull]
        unless valid_predicates.include?(predicate.to_s)
          errors << "Rule #{rule_num}, Condition #{cond_num}: invalid predicate '#{predicate}'. Valid: #{valid_predicates.join(', ')}"
        end
      end
    end
  end
end

def validate_smart_query_rules(rules)
  puts "🔍 Validating SmartQuery rules..."

  errors = SmartQueryValidator.validate_rules(rules)

  if errors.empty?
    puts "✅ Rules are valid!"
  else
    puts "❌ Found #{errors.size} error(s):"
    errors.each { |error| puts "   • #{error}" }
  end

  errors.empty?
end

smart_query_cheatsheet

# ------------------------------------------------------------------------------
# Common SmartQuery Patterns
# ------------------------------------------------------------------------------
def common_smart_query_patterns
  puts "\n🎯 Common SmartQuery Patterns:"

  puts "\n1. Active Teams:"
  puts "   [{ c: [{ a: 'active', p: 'eq', v: true }] }]"

  puts "\n2. Specific Team Types:"
  puts "   [{ c: [{ a: 'team_type.name', p: 'in', v: ['Store', 'DC'] }] }]"

  puts "\n3. Teams with Metadata:"
  puts "   [{ c: [{ a: 'metadata.STORE_TYPE', p: 'eq', v: 'Premium' }] }]"

  puts "\n4. Using Scopes:"
  puts "   [{ c: [{ s: 'active', v: nil }] }]"

  puts "\n5. Teams by Reference Pattern:"
  puts "   [{ c: [{ a: 'reference_number', p: 'like', v: 'S%' }] }]"

  puts "\n6. Multiple Conditions (AND):"
  puts "   [{ c: [{ a: 'active', p: 'eq', v: true }, { a: 'team_type.name', p: 'eq', v: 'Store' }] }]"

  puts "\n7. Alternative Conditions (OR):"
  puts "   [{ c: [{ a: 'team_type.name', p: 'eq', v: 'Store' }] },"
  puts "    { c: [{ a: 'team_type.name', p: 'eq', v: 'DC' }] }]"

  puts "\n8. User Security Roles:"
  puts "   [{ c: [{ a: 'user.security_role_id', p: 'eq', v: 5 }] }]"

  puts "\n9. Team Hierarchies:"
  puts "   [{ c: [{ s: 'descendants_for_ids', v: 123 }] }]"

  puts "\n10. Complex Nested:"
  puts "    [{ c: [{ a: 'user.metadata.ROLE', p: 'eq', v: 'Manager' },"
  puts "           { a: 'team.active', p: 'eq', v: true }] }]"
end
