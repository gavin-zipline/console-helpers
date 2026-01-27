
LEARNING_HELPER_VERSION = '1.0.0'
def learning_helper_cheatsheet
  learning_cheatsheet
end
ConsoleHelpers.register_helper("learning", LEARNING_HELPER_VERSION, method(:learning_helper_cheatsheet))
# frozen_string_literal: true

module LearningHelper
  def confirm_assignments(track)
    expected_user_ids = DistributionResolver.call(
      targets: track.distribution,
      distribution_target: :user
    )[:recipient_user_ids].sort

    actual_user_ids = track.track_enrollments.pluck(:user_id).uniq.sort

    missing = expected_user_ids - actual_user_ids
    extra = actual_user_ids - expected_user_ids

    puts "✅ Total expected: #{expected_user_ids.size}"
    puts "📥 Enrollments found: #{actual_user_ids.size}"
    puts "❌ Missing enrollments: #{missing.size}" unless missing.empty?
    disabled = User.where(id: missing).where.not(disabled_at: nil)

    if disabled.count == missing.count && missing.any?
      puts "💡 All missing users (#{missing.count}) are disabled. This explains the discrepancy."
    elsif disabled.any?
      puts "💡 #{disabled.count} of the #{missing.count} missing users are disabled."
    end

    puts "🛑 Extra enrollments: #{extra.size}" unless extra.empty?

    { expected: expected_user_ids, actual: actual_user_ids, missing: missing, extra: extra }
  end

  def resync_track_enrollments(track)
    puts "🔁 Enqueueing TrackSync Job for #{track.title} (#{track.id})"
    Learning::Enrollers::TrackSync::Job.perform_async(
      track.to_global_id.to_s,
      {}.to_json
    )
  end

  def list_learning_courses
    Learning::Course.limit(10).map(&:short_view)
  end

  def list_learning_tracks
    Learning::Track.limit(10).map(&:short_view)
  end

  def user_learning_summary(user)
    {
      user_id: user.id,
      enrollments: user.learning_enrollments.map { |e| "#{e.track.name} (#{e.track_id})" },
      tracks: user.learning_tracks.map { |t| "#{t.name} (#{t.id})" },
      completed_tracks: user.completed_learning_tracks.map { |t| "#{t.name} (#{t.id})" }
    }
  end

  def user_enrollments(user)
    Learning::Enrollment.where(user_id: user.id).map do |enrollment|
      "#{enrollment.track.name} (#{enrollment.track_id}) — Status: #{enrollment.status}"
    end
  end

  def track_enrollments(track)
    track.enrollments.includes(:user).map do |e|
      "#{e.user.name} (#{e.user_id}) — Status: #{e.status}"
    end
  end

  def track_summary(track)
    {
      id: track.id,
      title: track.title,
      course_ids: track.course_ids,
      enrollments_count: track.track_enrollments.count,
      distribution_target: track.distribution_target
    }
  end

  def refresh_distribution(track)
    Learning::RefreshDistributionListJob.perform_now(track.id)
    puts "🔄 Triggered RefreshDistributionListJob for Track #{track.name} (#{track.id})"
  end

  def learning_cheatsheet
    puts   "\n🚀🚀🚀 LEARNING HELPER — VERSION #{LEARNING_HELPER_VERSION} 🚀🚀🚀"
    puts "\n📘 Learning Helper Cheatsheet:"
    puts "🧠 list_learning_courses          # Show 10 recent learning courses"
    puts "📚 list_learning_tracks           # Show 10 recent learning tracks"
    puts "👤 user_learning_summary(user)    # Summary of a user's learning context"
    puts "📝 user_enrollments(user)         # List enrollments for a given user"
    puts "📈 track_enrollments(track)       # List enrollments for a given track"
    puts "🧾 track_summary(track)           # Summary of a given track"
    puts "🔁 refresh_distribution(track)    # Manually trigger distribution refresh"
    puts "📊 confirm_assignments(track)    # Validate enrollments match distribution"
    puts "♻️ resync_track_enrollments(track)   # Re-run the TrackSync job to sync enrollments to the track's distribution targets"
    puts
  end
end

