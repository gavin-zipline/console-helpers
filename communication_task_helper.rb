COMMUNICATION_TASK_HELPER_VERSION = "0.1.0"
def communication_task_helper_cheatsheet
  puts "\n📘 Communication Task Helper Cheatsheet:"
  puts "• Add your communication task helper methods here."
end
ConsoleHelpers.register_helper("communication_task", COMMUNICATION_TASK_HELPER_VERSION, method(:communication_task_helper_cheatsheet))


# communication_task_helper.rb
COMM_TASK_HELPER_VERSION = "0.1.0"
HELPER_VERSION = COMM_TASK_HELPER_VERSION

# == Communication Task Helper ==
# Tools for debugging and managing Communication::IndividualTask completion across teams

def completed_task_statuses(task_id:, comm_ref:, user_ids:)
  IndividualTaskStatus
    .where(task_id: task_id, communication_reference_id: comm_ref, user_id: user_ids, status: "complete")
    .group_by(&:team_id)
end

def copy_completed_status_to_team(user_ids:, task_id:, comm_ref:, from_team:, to_team:)
  user_ids.each do |uid|
    if IndividualTaskStatus.exists?(user_id: uid, task_id: task_id, communication_reference_id: comm_ref, team_id: to_team)
      puts "🔁 Task already marked complete for user #{uid} on team #{to_team}"
      next
    end

    existing = IndividualTaskStatus.find_by(user_id: uid, task_id: task_id, communication_reference_id: comm_ref, team_id: from_team)
    unless existing&.complete?
      puts "⚠️ Task not completed for user #{uid} on team #{from_team}, skipping"
      next
    end

    IndividualTaskStatus.create!(
      user_id: uid,
      task_id: task_id,
      communication_reference_id: comm_ref,
      team_id: to_team,
      status: "complete"
    )

    puts "✅ Marked complete for user #{uid} on team #{to_team}"
  end
end

def user_task_status_summary(user:, task_id:, comm_ref:)
  IndividualTaskStatus.where(user_id: user.id, task_id: task_id, communication_reference_id: comm_ref)
                      .map { |s| { team_id: s.team_id, status: s.status, deleted: s.deleted_at.present? } }
end

def communication_task_cheatsheet
  puts   "\n🚀🚀🚀 COMMUNICATION TASK HELPER — VERSION #{COMM_TASK_HELPER_VERSION} 🚀🚀🚀"
  puts   "\n📘 Communication Task Helper Cheatsheet:"
  puts   "\n🛠 Methods:"
  puts   "• completed_task_statuses(task_id:, comm_ref:, user_ids:)       → Grouped status records by team"
  puts   "• copy_completed_status_to_team(...)                          → Copy completed status to another team"
  puts   "• user_task_status_summary(user:, task_id:, comm_ref:)        → Show all status records for a user"
end

communication_task_cheatsheet
