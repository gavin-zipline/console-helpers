ASSESSMENT_SURVEY_HELPER_VERSION = "0.2.4"

require 'csv'

def survey_response_csv(survey)
  CSV.generate do |csv|
    csv << ["Store", "Name", "Employee Number", "Status", "Started At", "Submitted At", "Question", "Answer"]
    survey.response_sets.includes(:user, :team_membership, responses: [:question]).find_each do |rs|
      team = rs.team_membership&.team
      user = rs.user
      rs.responses.each do |response|
        question = response.question
        answer_ids = Array(response.value)
        answers_map = question.answers.index_by(&:id)
        answer = answer_ids.map { |id| answers_map[id]&.value }.compact.join(", ")
        csv << [
          team&.reference_number,
          user&.name,
          user&.employee_number,
          rs.status,
          rs.created_at,
          rs.submitted_at || rs.completed_at,
          question&.title,
          answer
        ]
      end
    end
  end
end

Survey::Survey.class_eval do
  def overview
    puts

    self.sections.order(:order).each do |section|
      puts "📚 Section: #{section.title} (#{section.id})"
      section.questions.order(:order).each do |q|
        puts "  ❓ Question: #{q.title} (#{q.id})"
        puts "     - Type: #{q.display_type}"
        puts "     - Required: #{q.required}"
        puts "     - Conditional: #{q.conditional?}"
        puts "     - Answers:"
        q.answers.each do |a|
          puts "         • #{a.value} (#{a.id})"
        end
      end
      puts
    end

    puts "📝 Survey Overview: #{self.title} (#{self.id})"
    puts "  Questions: #{self.questions_count}"
    puts "  Ends On: #{self.ends_on || 'No deadline'}"
    puts "  Graded: #{self.graded}"
    puts "  Sections: #{self.sections.count}"
    puts "  Required Questions: #{self.questions.select(&:required).count}"
    puts "🔍 Conditional Logic Detected" if self.conditional_logic?
    puts "✅ Completed Response Sets: #{self.completed_response_sets.count}"
    puts "❌ Incomplete Response Sets: #{self.incomplete_response_sets.count}"
    puts "📭 Empty Response Sets: #{self.empty_response_sets.count}"
    puts "👤 For Team: #{self.for_team?}"
    puts "⚠️ Ends in Past: #{self.ended?}" if self.ended?
    puts

    nil
  end

  def completed_response_sets
    response_sets.where.not(submitted_at: nil)
  end

  def incomplete_response_sets
    response_sets.where(submitted_at: nil).joins(:responses).distinct.tap do |incomplete|
      class << incomplete
        def count_by_last_question
          each_with_object(Hash.new(0)) do |rs, counts|
            last = rs.responses.order(:created_at).last
            next unless last&.question
            label = "#{last.question.title} (#{last.question_id})"
            counts[label] += 1
          end
        end
      end
    end
  end

  def empty_response_sets
    response_sets.left_joins(:responses).where(responses: { id: nil })
  end
end

def questions_with_follow_ups(survey)
  survey.questions.select { |q| q.follow_up_rules.present? }.map(&:title)
end

def incomplete_response_sets_by_team(survey)
  survey.incomplete_response_sets.includes(:team_membership).group_by { |rs| rs.team_membership&.team&.reference_number }
end

def response_sets_with_missing_users(survey)
  survey.response_sets.includes(:user).select { |rs| rs.user.nil? }
end

def responses_missing_questions(survey)
  survey.response_sets.includes(:responses).flat_map(&:responses).select { |r| r.question.nil? }
end

def response_sets_with_duplicate_users(survey)
  grouped = survey.response_sets.group_by(&:user_id)
  grouped.select { |user_id, sets| user_id && sets.size > 1 }
end

def response_sets_with_no_answers(survey)
  survey.response_sets.includes(:responses).select { |rs| rs.responses.all? { |r| r.value.blank? } }
end

def assessments_and_surveys_cheatsheet
  puts   "\n🚀🚀🚀 ASSESSMENTS & SURVEYS HELPER — VERSION #{ASSESSMENT_SURVEY_HELPER_VERSION} 🚀🚀🚀"
  puts "\n📘 Cheatsheet:"
  puts "- survey_response_csv(survey) — Generate CSV string from a Survey::Survey instance"
  puts "- overview — Print a detailed summary of a Survey::Survey instance"
  puts "- questions_with_follow_ups(survey) — List question titles that have follow-up rules"
  puts "- incomplete_response_sets_by_team(survey) — Group incomplete response sets by team"
  puts "- response_sets_with_missing_users(survey) — Find response sets with missing user associations"
  puts "- responses_missing_questions(survey) — Find responses where the question is nil (deleted or corrupted)"
  puts "- response_sets_with_duplicate_users(survey) — Find users who submitted multiple response sets"
  puts "- response_sets_with_no_answers(survey) — Find response sets where all answers are blank"
  puts "- (coming soon)"
  puts
end

assessments_and_surveys_cheatsheet
