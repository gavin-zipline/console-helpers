# frozen_string_literal: true

COMMUNICATION_HELPER_VERSION = "0.1.0"

module CommunicationHelper
  def task_view(communication)
    communication.tasks.map { |t| [t.id, t.title, t.type, t.due_on] }
  end

  def task_view_ids(communication)
    communication.tasks.map(&:id)
  end

  def communication_helper_cheatsheet
    puts "\n📘 Communication Helper — VERSION #{COMMUNICATION_HELPER_VERSION}"
    puts "\n🛠 Methods:"
    puts "• task_view(communication)     → View tasks inside a Communication record"
    puts "• task_view_ids(communication) → View task IDs inside a Communication record"
  end
end

include CommunicationHelper
communication_helper_cheatsheet
