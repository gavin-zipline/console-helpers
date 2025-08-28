SIDEKIQ_HELPER_VERSION = "0.1.1"
HELPER_VERSION = SIDEKIQ_HELPER_VERSION

def sidekiq(organization = org)
  scheduled_jobs = Sidekiq::ScheduledSet.new

  # Filter jobs by the given organization
  filtered_jobs = scheduled_jobs.select do |job|
    job.item['apartment'] == organization
  end

  # Generate summary report
  total_jobs = filtered_jobs.size
  job_classes = filtered_jobs.each_with_object(Hash.new(0)) do |job, counts|
    counts[job.klass] += 1
  end

  # Display the summary
  puts "\n=== Summary of scheduled SideKiq jobs for '#{organization}' ==="
  puts "Total Jobs: #{total_jobs}"
  puts "Job Class Breakdown:"
  job_classes.each do |job_class, count|
    puts "  - #{job_class}: #{count} job(s)"
  end
  puts "===================================\n"

  # Return the summary as a hash for further use if needed
  {
    organization: organization,
    total_jobs: total_jobs,
    job_classes: job_classes
  }
end

def sidekiq_status
  puts "=== Comprehensive Sidekiq Status ==="

  # Scheduled jobs
  scheduled = Sidekiq::ScheduledSet.new
  puts "⏳ Scheduled Jobs: #{scheduled.size}"

  # Retry jobs
  retries = Sidekiq::RetrySet.new
  puts "♻️ Retry Jobs: #{retries.size}"

  # Queues
  queues = Sidekiq::Queue.all
  queues.each do |queue|
    puts "📥 Queue '#{queue.name}' — Size: #{queue.size}"
  end

  # Currently processing
  workers = Sidekiq::Workers.new
  puts "⚙️  Jobs Currently Running: #{workers.size}"

  puts "===================================="
end

def sidekiq_cheatsheet
  puts   "\n🚀🚀🚀 SIDEKIQ HELPER — VERSION #{SIDEKIQ_HELPER_VERSION} 🚀🚀🚀"
  puts "\n📘 Sidekiq Helper Cheatsheet:"
  puts "\n🛠 Methods:"
  puts "• sidekiq → Summary of scheduled Sidekiq jobs for current org (#{org})"
  puts "• sidekiq_status → Show full Sidekiq state (scheduled, queued, retry, running)"
end

sidekiq_cheatsheet
