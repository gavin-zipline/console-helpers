# ------------------------------------------------------------------------------
# SCORM Helper
# ------------------------------------------------------------------------------
# Purpose: Debug SCORM integration issues, analyze CDN links, and troubleshoot
#          SCORM reporting problems in ResourceLibrary resources
# Usage: Load via `gh("scorm")` then use `scorm_cheatsheet` for docs
# Safety: Read-only analysis functions, safe for production use

SCORM_HELPER_VERSION = "1.0.1"

require 'uri'
require 'cgi'

def scorm_helper_version
  puts "🔧 SCORM Helper Version: #{SCORM_HELPER_VERSION}"
  SCORM_HELPER_VERSION
end

# ------------------------------------------------------------------------------
# Core Helper Methods
# ------------------------------------------------------------------------------
# Add this to your scorm_helper.rb file

def get_s3_key(training_file)
  if training_file.attachment_blob
    key = training_file.attachment_blob.key
    puts "🔑 S3 Key: #{key}"
    puts "📁 Filename: #{training_file.filename}"
    puts "📊 Size: #{(training_file.attachment_blob.byte_size / 1.megabyte.to_f).round(2)}MB"
    puts "🏷️ Content Type: #{training_file.attachment_blob.content_type}"
    puts "✅ Extracted: #{training_file.attachment_blob.metadata['extracted']}"
    puts "📦 SCORM: #{training_file.attachment_blob.metadata['scorm']}"
    key
  else
    puts "❌ No attachment blob found for training file"
    nil
  end
end

def download_scorm_file_info(training_file)
  key = get_s3_key(training_file)
  return nil unless key

  puts "\n🌐 Download Information:"
  puts "Service: #{training_file.attachment_blob.service_name}"
  puts "S3 URL: #{training_file.s3_url}"
  puts "Direct Key: #{key}"

  # For AWS CLI download (if you have access)
  bucket = case Rails.env
           when "production" then "zipline-production-cloudfront"
           when "staging" then "zipline-staging-cloudfront"
           else "zipline-development-cloudfront"
           end

  # Add org prefix check for S3 path
  org_prefix = "aeo"  # Based on your S3 console screenshot

  puts "\n💻 AWS CLI Commands:"
  puts "# Try with org prefix (recommended based on S3 console):"
  puts "aws s3 cp s3://#{bucket}/#{org_prefix}/#{key} ./#{training_file.filename}"
  puts ""
  puts "# Check if file exists:"
  puts "aws s3 ls s3://#{bucket}/#{org_prefix}/#{key}"
  puts ""
  puts "# Original path (may not work):"
  puts "aws s3 cp s3://#{bucket}/#{key} ./#{training_file.filename}"

  key
end

def diagnose_missing_s3_file(training_file)
  puts "🔍 Diagnosing S3 file location for: #{training_file.filename}"
  puts ""

  key = training_file.attachment_blob.key
  puts "🔑 Blob Key: #{key}"
  puts "📊 File Size: #{training_file.attachment_blob.byte_size} bytes"
  puts ""

  # Check S3 URL for path hints
  s3_url = training_file.s3_url
  if s3_url
    uri = URI.parse(s3_url)
    extracted_path = uri.path.gsub('/secure/', '')
    puts "🌐 S3 URL Path: #{extracted_path}"
    puts "Full URL: #{s3_url}"
  end

  # Try different bucket/path combinations
  bucket = "zipline-production-cloudfront"
  org_prefix = "aeo"  # From your console screenshot

  puts ""
  puts "💻 Try these AWS CLI commands:"
  puts ""
  puts "# With org prefix (likely correct):"
  puts "aws s3 cp s3://#{bucket}/#{org_prefix}/#{key} ./#{training_file.filename}"
  puts ""
  puts "# Check if file exists with ls:"
  puts "aws s3 ls s3://#{bucket}/#{org_prefix}/#{key}"
  puts ""

  # Check for extracted directory structure
  puts "🗂️ If this is extracted content, try:"
  puts "aws s3 sync s3://#{bucket}/#{org_prefix}/training_files/#{training_file.id}/ ./#{training_file.name}/"

  key
end

def investigate_tiny_scorm_file(training_file)
  puts "🔍 Investigating suspiciously small SCORM file..."
  puts ""

  diagnose_missing_s3_file(training_file)
  puts ""

  # Check if this might be a reference file
  puts "=== Size Analysis ==="
  size_bytes = training_file.attachment_blob.byte_size
  puts "File size: #{size_bytes} bytes (#{(size_bytes / 1024.0).round(2)} KB)"

  if size_bytes < 10.kilobytes
    puts "🚨 EXTREMELY SMALL for SCORM package!"
    puts "   Typical SCORM packages are 1MB+ even when minimal"
    puts "   This suggests:"
    puts "   • Corrupted upload"
    puts "   • Reference/pointer file only"
    puts "   • Failed extraction left stub file"
  end

  # Look for the actual SCORM content
  puts ""
  puts "=== Looking for actual SCORM content ==="

  # Check if there are other training files with similar names
  similar_files = Training::File.where("filename ILIKE ?", "%denim-dna%")
                               .where.not(id: training_file.id)
                               .order(created_at: :desc)

  if similar_files.any?
    puts "📁 Found similar training files:"
    similar_files.each do |file|
      size_mb = file.attachment_blob.byte_size / 1.megabyte.to_f
      puts "  • #{file.filename} - #{size_mb.round(1)}MB (#{file.created_at.strftime('%m/%d/%Y')})"
      puts "    ID: #{file.id}"
    end
    puts ""
    puts "💡 The actual SCORM content might be in one of these files"
  end

  training_file
end

def check_extracted_files(training_file)
  # Check if there are extracted files in a different location
  tf_id = training_file.id

  # Common patterns for extracted SCORM files
  possible_paths = [
    "#{tf_id}/index.html",
    "#{tf_id}/imsmanifest.xml",
    "#{tf_id}/scorm/index.html",
    "training_files/#{tf_id}/index.html",
    "aeo/training_files/#{tf_id}/index.html"
  ]

  puts "Checking for extracted files at common paths:"
  possible_paths.each do |path|
    puts "  - #{path}"
  end

  # Check if the S3 URL pattern gives us clues
  s3_url = training_file.s3_url
  if s3_url
    uri = URI.parse(s3_url)
    extracted_path = uri.path.gsub('/secure/', '')
    puts ""
    puts "S3 URL suggests path: #{extracted_path}"
    puts "Full S3 URL: #{s3_url}"
  end
end

def check_alternative_storage(training_file)
  # Check if file might be in a different bucket/location
  buckets = [
    "zipline-production-cloudfront",
    "zipline-production",
    "zipline-uploads-production",
    "cdn-retailzipline-com"
  ]

  puts "File might be in alternative buckets:"
  buckets.each do |bucket|
    puts "  - s3://#{bucket}/#{training_file.attachment_blob.key}"
    puts "  - s3://#{bucket}/aeo/#{training_file.attachment_blob.key}"
  end

  # Check if it's a very old file with different storage pattern
  puts ""
  puts "File age: #{((Time.current - training_file.created_at) / 1.day).round(1)} days"
  if training_file.created_at < 6.months.ago
    puts "⚠️ Old file - may use legacy storage pattern"
  end
end

# == 🔍 CDN LINK ANALYSIS ==
# Methods for analyzing CDN links in ResourceLibrary content

def extract_cdn_links_from_html(html)
  return [] if html.blank?
  # Find CDN URLs in HTML content
  cdn_host = case Rails.env
             when "production" then "cdn.retailzipline.com"
             when "staging"    then "cdn.retailzipline.xyz"
             else                   "cdn.retailzipline.dev"
             end

  urls = html.scan(%r{https?://#{Regexp.escape(cdn_host)}/secure/[^\s"')]+})
  urls.uniq
end

def parse_cdn_url(url)
  cdn_host = case Rails.env
             when "production" then "cdn.retailzipline.com"
             when "staging"    then "cdn.retailzipline.xyz"
             else                   "cdn.retailzipline.dev"
             end

  uri = URI.parse(url) rescue nil
  return { url: url, error: 'bad URI' } unless uri&.host == cdn_host

  # Parse query parameters
  q = CGI.parse(uri.query.to_s) # => { "token"=>["..."], "X-Amz-Expires"=>["300"], ... }
  tokens = q.slice(
    'token',                    # common custom token param
    'signature', 'sig',         # other customs
    'X-Amz-Algorithm', 'X-Amz-Credential', 'X-Amz-Date', 'X-Amz-Expires', 'X-Amz-Signature', 'X-Amz-Security-Token',
    'Policy', 'Signature', 'Key-Pair-Id'  # CloudFront signed URL style
  ).transform_values { |v| v.first }

  {
    url: url,
    scheme: uri.scheme,
    host: uri.host,
    path: uri.path,
    query_keys: q.keys.sort,
    tokens: tokens
  }
end

def report_resource_cdn_links(resource)
  links = extract_cdn_links_from_html(resource.body.to_s)
  return puts "No CDN links for #{resource.name} (#{resource.id})" if links.empty?

  puts "#{resource.name} (#{resource.id}):"
  links.each do |u|
    info = parse_cdn_url(u)
    if info[:error]
      puts "  ! #{u}  [#{info[:error]}]"
    else
      # Print path and token fragments
      token_preview =
        if info[:tokens].present?
          info[:tokens].map { |k,v| "#{k}=#{v.to_s[0,8]}…" }.join(' ')
        else
          '(no token params)'
        end
      puts "  - #{info[:path]} | #{token_preview}"
    end
  end
  nil
end

def report_cdn_links_for_resources(scope)
  scope.find_each do |res|
    report_resource_cdn_links(res)
  end
  nil
end

# == 🔍 SCORM DEBUGGING ==
# High-level debugging functions for SCORM issues

def audit_scorm_cdn_links
  cdn_host = case Rails.env
             when "production" then "cdn.retailzipline.com"
             when "staging"    then "cdn.retailzipline.xyz"
             else                   "cdn.retailzipline.dev"
             end

  puts "🔍 Auditing SCORM CDN links in Resource Library..."
  puts "Environment: #{Rails.env} (#{cdn_host})"
  puts "=" * 60

  # Find resources with secure CDN links
  scope = ResourceLibrary::Resource.where("body ILIKE ?", "%//#{cdn_host}/secure/%")
  total_resources = scope.count

  puts "Found #{total_resources} resources with secure CDN links"
  puts ""

  if total_resources > 0
    # Focus on training_files which are likely SCORM
    training_scope = ResourceLibrary::Resource.where("body ILIKE ?", "%//#{cdn_host}/secure/%/training_files/%")
    training_count = training_scope.count

    puts "📚 #{training_count} resources reference training_files (likely SCORM)"
    puts ""

    if training_count > 0
      puts "Training file resources:"
      report_cdn_links_for_resources(training_scope.limit(10))
      puts "..." if training_count > 10
    end
  end

  puts ""
  puts "💡 Reminder: SCORM files should be drag-and-dropped onto resources,"
  puts "   not pasted as direct CDN links to prevent reporting issues."

  nil
end

def find_scorm_by_training_file_id(training_file_id)
  training_file = Training::File.find(training_file_id)
  puts "Training File: #{training_file.id}"
  puts "Filename: #{training_file.filename}"
  puts "Created: #{training_file.created_at}"
  puts ""

  # Find associated resources
  resources = ResourceLibrary::Resource.where("body ILIKE ?", "%#{training_file_id}%")

  puts "📚 Found #{resources.count} resources referencing this training file:"
  resources.each do |res|
    puts "  - #{res.name} (#{res.id})"
  end

  training_file
rescue ActiveRecord::RecordNotFound
  puts "❌ Training file not found: #{training_file_id}"
  nil
end

def debug_scorm_reporting_for_resource(resource_permalink_or_id)
  resource = ResourceLibrary::Resource.for_permalink_or_id(resource_permalink_or_id)

  puts "🔍 Debugging SCORM reporting for resource:"
  puts "Name: #{resource.name}"
  puts "ID: #{resource.id}"
  puts "Created: #{resource.created_at}"
  puts ""

  # Check for CDN links
  puts "=== CDN Links Analysis ==="
  report_resource_cdn_links(resource)
  puts ""

  # Look for training files in the content
  training_file_ids = resource.body.to_s.scan(/([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})/).flatten.uniq

  if training_file_ids.any?
    puts "=== Training Files Found ==="
    training_file_ids.each do |tf_id|
      training_file = Training::File.find_by(id: tf_id)
      if training_file
        puts "✅ Training File: #{tf_id}"
        puts "   Filename: #{training_file.filename}"
        puts "   Results count: #{training_file.results.count}"

        recent_results = training_file.results.order(created_at: :desc).limit(5)
        if recent_results.any?
          puts "   Recent completions:"
          recent_results.each do |result|
            status = result.results.dig("core", "lesson_status") || "unknown"
            puts "     - #{result.user.name}: #{status} (#{result.created_at.strftime('%m/%d/%Y')})"
          end
        else
          puts "   ⚠️ No completion results found"
        end
      else
        puts "❌ Training File not found: #{tf_id}"
      end
      puts ""
    end
  else
    puts "⚠️ No training file UUIDs found in resource body"
  end

  resource
rescue ActiveRecord::RecordNotFound
  puts "❌ Resource not found: #{resource_permalink_or_id}"
  nil
end

# ------------------------------------------------------------------------------
# Documentation & Help
# ------------------------------------------------------------------------------

def scorm_cheatsheet
  puts "\n🎯🎯🎯 SCORM HELPER — VERSION #{SCORM_HELPER_VERSION} 🎯🎯🎯"
  puts "\n📘 Purpose: Debug SCORM integration and reporting issues"
  puts "Originally created for True Society SCORM issue #9736\n"

  puts "=" * 70
  puts "🔍 AUDIT & ANALYSIS FUNCTIONS"
  puts "=" * 70

  puts "• audit_scorm_cdn_links"
  puts "  └ Comprehensive audit of all ResourceLibrary SCORM CDN links"
  puts "  └ Identifies improperly integrated SCORM files"
  puts "  └ Shows environment-specific CDN host and counts"
  puts ""

  puts "• debug_scorm_reporting_for_resource(permalink_or_id)"
  puts "  └ Deep dive analysis of a specific resource's SCORM setup"
  puts "  └ Shows CDN links, training files, and recent completions"
  puts "  └ Perfect for investigating 'no results in report' issues"
  puts ""

  puts "• report_resource_cdn_links(resource)"
  puts "  └ Analyzes CDN links in a single resource"
  puts "  └ Shows paths and token fragments"
  puts ""

  puts "• find_scorm_by_training_file_id(training_file_id)"
  puts "  └ Find all resources that reference a specific training file"
  puts "  └ Useful for impact analysis"
  puts ""

  puts "• find_scorm_lessons_with_issues"
  puts "  └ Scans all SCORM lessons for common problems"
  puts "  └ Finds orphaned lessons, unextracted files, missing results"
  puts ""

  puts "• analyze_scorm_lesson(lesson_id)"
  puts "  └ Comprehensive analysis of a specific SCORM lesson"
  puts "  └ Shows training file, results, enrollments, and mismatches"
  puts ""

  puts "• validate_scorm_setup(training_file_id)"
  puts "  └ Validates proper SCORM training file setup"
  puts "  └ Checks extraction, lesson association, and resource usage"
  puts ""

  puts "• compare_scorm_integrations(resource_id, lesson_id)"
  puts "  └ Compare ResourceLibrary vs Learning lesson SCORM usage"
  puts "  └ Identify integration mismatches"
  puts ""

  puts "=" * 70
  puts "📊 FILE SIZE ANALYSIS FUNCTIONS"
  puts "=" * 70

  puts "• analyze_scorm_file_sizes(limit: 20)"
  puts "  └ Find largest SCORM files and flag optimization opportunities"
  puts "  └ Identifies timeout risks, mobile issues, and large files"
  puts ""

  puts "• find_oversized_scorm_by_customer(customer_name, size_threshold_mb: 100)"
  puts "  └ Find large SCORM files for specific customers"
  puts "  └ Perfect for proactive customer outreach"
  puts ""

  puts "• check_scorm_extraction_failures(days_back: 7)"
  puts "  └ Find recent SCORM files that failed extraction"
  puts "  └ Often related to oversized files"
  puts ""

  puts "• scorm_optimization_guide_summary"
  puts "  └ Display quick reference for SCORM optimization"
  puts "  └ Share with customers who have large files"
  puts ""

  puts "=" * 70
  puts "🧪 COMMON USAGE EXAMPLES"
  puts "=" * 70

  puts "# Start here - quick audit of all SCORM issues"
  puts "audit_scorm_cdn_links"
  puts ""

  puts "# Find SCORM lessons with problems"
  puts "find_scorm_lessons_with_issues"
  puts ""

  puts "# Deep dive analysis of a specific lesson"
  puts "analyze_scorm_lesson(12345)  # lesson ID"
  puts ""

  puts "# Debug a specific resource (like True Society bridal course)"
  puts 'debug_scorm_reporting_for_resource("e77e55ab-bridal-live-for-managers")'
  puts ""

  puts "# Validate a training file setup"
  puts 'validate_scorm_setup("eaedaa48-5d15-4686-a526-9e51a5e47b28")'
  puts ""

  puts "# Compare resource vs lesson integration"
  puts "compare_scorm_integrations(resource_id, lesson_id)"
  puts ""

  puts "# Analyze file sizes and find optimization opportunities"
  puts "analyze_scorm_file_sizes(limit: 20)"
  puts ""

  puts "# Find large files by customer for proactive outreach"
  puts 'find_oversized_scorm_by_customer("customer_name", size_threshold_mb: 100)'
  puts ""

  puts "# Check for recent extraction failures"
  puts "check_scorm_extraction_failures(days_back: 7)"
  puts ""

  puts "# Show optimization guide summary"
  puts "scorm_optimization_guide_summary"
  puts ""

  puts "# Find all resources using a specific training file"
  puts 'find_scorm_by_training_file_id("eaedaa48-5d15-4686-a526-9e51a5e47b28")'
  puts ""

  puts "# Analyze resources in bulk"
  puts "scope = ResourceLibrary::Resource.where('body ILIKE ?', '%/training_files/%')"
  puts "report_cdn_links_for_resources(scope)"
  puts ""

  puts "=" * 70
  puts "💡 TROUBLESHOOTING TIPS"
  puts "=" * 70

  puts "🚨 Common SCORM Reporting Issues:"
  puts "• Hard-coded CDN URLs with expired signatures"
  puts "• Manual paste instead of drag-and-drop file attachment"
  puts "• Missing connection between resource and training file"
  puts ""

  puts "✅ Proper SCORM Integration:"
  puts "• Drag and drop SCORM zip file onto resource in edit mode"
  puts "• System generates stable /field/training/files/ links"
  puts "• Completions automatically flow to E-Learning reports"
  puts ""

  puts "🔧 Version: #{SCORM_HELPER_VERSION}"
  puts "📞 Contact: @gavin-zipline for questions about SCORM debugging"
  puts ""
end

# == 🎯 LEARNING LESSON ANALYSIS ==
# Methods for analyzing Learning::ScormLesson objects

def find_scorm_lessons_with_issues
  puts "🔍 Finding SCORM lessons with potential issues..."

  issues = []

  # Find SCORM lessons without training files
  orphaned_lessons = Learning::ScormLesson.includes(:training_file).where(training_file: nil)
  if orphaned_lessons.any?
    issues << {
      type: "Missing Training Files",
      count: orphaned_lessons.count,
      lessons: orphaned_lessons.limit(5).map { |l| "#{l.title} (#{l.id})" }
    }
  end

  # Find lessons with non-extracted training files
  unextracted = Learning::ScormLesson.joins(:training_file)
                                   .where(training_files: { deleted_at: nil })
                                   .select { |l| l.training_file && !l.training_file.extracted? }
  if unextracted.any?
    issues << {
      type: "Unextracted Training Files",
      count: unextracted.count,
      lessons: unextracted.first(5).map { |l| "#{l.title} (#{l.id})" }
    }
  end

  # Find training files with no results despite being in courses
  no_results = Learning::ScormLesson.joins(:training_file)
                                  .where(training_files: { deleted_at: nil })
                                  .select { |l| l.training_file && l.training_file.results.empty? && l.course.enrollments.any? }
  if no_results.any?
    issues << {
      type: "No Results Despite Enrollments",
      count: no_results.count,
      lessons: no_results.first(5).map { |l| "#{l.title} (#{l.id}) - #{l.course.enrollments.count} enrollments" }
    }
  end

  if issues.empty?
    puts "✅ No SCORM lesson issues found!"
  else
    issues.each do |issue|
      puts ""
      puts "⚠️ #{issue[:type]}: #{issue[:count]} found"
      issue[:lessons].each { |lesson| puts "   - #{lesson}" }
      puts "   ..." if issue[:count] > 5
    end
  end

  issues
end

def analyze_scorm_lesson(lesson_id)
  lesson = Learning::ScormLesson.find(lesson_id)

  puts "🎯 SCORM Lesson Analysis: #{lesson.title}"
  puts "ID: #{lesson.id}"
  puts "Course: #{lesson.course.title} (#{lesson.course.id})"
  puts "Inline: #{lesson.inline?}"
  puts "Require Completion: #{lesson.require_completion?}"
  puts ""

  # Training File Analysis
  if lesson.training_file
    tf = lesson.training_file
    puts "=== Training File ==="
    puts "ID: #{tf.id}"
    puts "Filename: #{tf.filename}"
    puts "Extracted: #{tf.extracted?}"
    puts "SCORM: #{tf.scorm?}"
    puts "Created: #{tf.created_at}"
    puts "Results count: #{tf.results.count}"

    if tf.extracted?
      puts "S3 URL: #{tf.s3_url}"
    else
      puts "⚠️ File not extracted - may be processing or failed"
    end
    puts ""

    # Results Analysis
    if tf.results.any?
      puts "=== Recent Results ==="
      tf.results.order(created_at: :desc).limit(10).each do |result|
        status = result.results.dig("core", "lesson_status") || "unknown"
        puts "  #{result.user.name}: #{status} (#{result.created_at.strftime('%m/%d/%Y %H:%M')})"
      end
    else
      puts "⚠️ No results found"
    end
  else
    puts "❌ No training file associated"
  end

  puts ""

  # Enrollment Analysis
  enrollments = lesson.lesson_enrollments.includes(:user)
  puts "=== Enrollments ==="
  puts "Total: #{enrollments.count}"

  if enrollments.any?
    status_counts = enrollments.group(:status).count
    puts "Status breakdown:"
    status_counts.each { |status, count| puts "  #{status}: #{count}" }

    # Check for mismatched enrollments vs results
    if lesson.training_file
      result_user_ids = lesson.training_file.results.pluck(:user_id).uniq
      enrollment_user_ids = enrollments.pluck(:user_id).uniq

      missing_results = enrollment_user_ids - result_user_ids
      if missing_results.any?
        puts ""
        puts "⚠️ #{missing_results.count} users have enrollments but no SCORM results:"
        User.where(id: missing_results.first(5)).each do |user|
          enrollment = enrollments.find { |e| e.user_id == user.id }
          puts "  - #{user.name} (#{enrollment.status})"
        end
        puts "  ..." if missing_results.count > 5
      end
    end
  end

  lesson
rescue ActiveRecord::RecordNotFound
  puts "❌ SCORM lesson not found: #{lesson_id}"
  nil
end

def compare_scorm_integrations(resource_id, lesson_id)
  puts "🔍 Comparing SCORM integrations..."
  puts ""

  # Analyze resource
  puts "=== ResourceLibrary::Resource ==="
  resource = ResourceLibrary::Resource.find(resource_id)
  puts "Name: #{resource.name}"
  puts "ID: #{resource.id}"
  report_resource_cdn_links(resource)
  puts ""

  # Analyze lesson
  puts "=== Learning::ScormLesson ==="
  lesson = Learning::ScormLesson.find(lesson_id)
  puts "Title: #{lesson.title}"
  puts "ID: #{lesson.id}"

  if lesson.training_file
    puts "Training File ID: #{lesson.training_file.id}"
    puts "S3 URL: #{lesson.training_file.s3_url}"
    puts "Results: #{lesson.training_file.results.count}"
  else
    puts "❌ No training file"
  end

  puts ""
  puts "=== Comparison ==="

  # Check if resource and lesson reference the same training file
  resource_tf_ids = extract_training_file_ids_from_html(resource.body.to_s)
  lesson_tf_id = lesson.training_file&.id

  if lesson_tf_id && resource_tf_ids.include?(lesson_tf_id)
    puts "✅ Resource and lesson reference the same training file: #{lesson_tf_id}"
  elsif lesson_tf_id
    puts "⚠️ Resource and lesson reference different training files"
    puts "   Resource: #{resource_tf_ids.join(', ')}"
    puts "   Lesson: #{lesson_tf_id}"
  else
    puts "❌ Lesson has no training file to compare"
  end

  { resource: resource, lesson: lesson }
rescue ActiveRecord::RecordNotFound => e
  puts "❌ Record not found: #{e.message}"
  nil
end

def extract_training_file_ids_from_html(html)
  # Extract UUIDs that look like training file IDs
  html.scan(/([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})/).flatten.uniq
end

# == 🔧 SCORM DEBUGGING UTILITIES ==
# Helper methods for common SCORM troubleshooting tasks

def fix_orphaned_scorm_resource(resource_permalink_or_id)
  puts "🔧 Attempting to fix orphaned SCORM resource..."

  resource = ResourceLibrary::Resource.for_permalink_or_id(resource_permalink_or_id)
  training_file_ids = extract_training_file_ids_from_html(resource.body.to_s)

  if training_file_ids.empty?
    puts "❌ No training file IDs found in resource content"
    return false
  end

  training_file_id = training_file_ids.first
  training_file = Training::File.find_by(id: training_file_id)

  if training_file.nil?
    puts "❌ Training file not found: #{training_file_id}"
    return false
  end

  puts "Found training file: #{training_file.filename} (#{training_file.id})"

  # Check if there's an existing lesson for this training file
  existing_lesson = Learning::ScormLesson.find_by(training_file: training_file)

  if existing_lesson
    puts "✅ Training file already has a lesson: #{existing_lesson.title} (#{existing_lesson.id})"
    return existing_lesson
  end

  puts "⚠️ Training file exists but has no associated lesson"
  puts "   Consider creating a proper Learning::ScormLesson for this training file"
  puts "   or check if the resource should be using the drag-and-drop method instead"

  training_file
end

def validate_scorm_setup(training_file_id)
  puts "🔍 Validating SCORM setup for training file: #{training_file_id}"

  training_file = Training::File.find(training_file_id)

  puts "=== Training File Validation ==="
  puts "✅ Training file exists: #{training_file.filename}"
  puts "✅ Extracted: #{training_file.extracted?}" if training_file.extracted?
  puts "❌ Not extracted" unless training_file.extracted?
  puts "✅ SCORM: #{training_file.scorm?}" if training_file.scorm?
  puts "❌ Not marked as SCORM" unless training_file.scorm?

  # Check for associated lessons
  lessons = Learning::ScormLesson.where(training_file: training_file)
  puts ""
  puts "=== Associated Lessons ==="
  if lessons.any?
    lessons.each do |lesson|
      puts "✅ Lesson: #{lesson.title} (#{lesson.id})"
      puts "   Course: #{lesson.course.title}"
      puts "   Inline: #{lesson.inline?}"
    end
  else
    puts "⚠️ No Learning::ScormLesson objects found"
  end

  # Check for resource library usage
  resources = ResourceLibrary::Resource.where("body ILIKE ?", "%#{training_file_id}%")
  puts ""
  puts "=== Resource Library Usage ==="
  if resources.any?
    resources.each do |resource|
      puts "⚠️ Resource: #{resource.name} (#{resource.id})"
      report_resource_cdn_links(resource)
    end
    puts ""
    puts "💡 These resources may be using manual CDN links instead of proper integration"
  else
    puts "✅ No resource library references found"
  end

  training_file
rescue ActiveRecord::RecordNotFound
  puts "❌ Training file not found: #{training_file_id}"
  nil
end

# == 📊 SCORM FILE SIZE ANALYSIS ==
# Methods for analyzing SCORM file sizes and flagging optimization opportunities

def analyze_scorm_file_sizes(limit: 20)
  puts "📊 Analyzing SCORM file sizes..."
  puts "=" * 60

  # Find all SCORM training files with their blob sizes
  scorm_files = Training::File.joins(:attachment)
                             .where(deleted_at: nil)
                             .where(active_storage_blobs: { metadata: { scorm: true } })
                             .includes(attachment: :blob)
                             .order('active_storage_blobs.byte_size DESC')
                             .limit(limit)

  if scorm_files.empty?
    puts "No SCORM files found"
    return
  end

  large_files = []
  timeout_risk = []
  mobile_issues = []

  puts "Top #{limit} largest SCORM files:"
  puts ""

  scorm_files.each_with_index do |file, index|
    size_mb = file.blob.byte_size / 1.megabyte.to_f
    size_str = "#{size_mb.round(1)}MB"

    # Flag different severity levels
    flags = []
    if size_mb > 500
      flags << "🚨 TIMEOUT RISK"
      timeout_risk << file
    elsif size_mb > 100
      flags << "⚠️ LARGE"
      large_files << file
    end

    if size_mb > 50
      flags << "📱 MOBILE ISSUES"
      mobile_issues << file
    end

    status = file.extracted? ? "✅" : "❌"

    puts "#{index + 1}. #{file.filename} - #{size_str} #{flags.join(' ')} #{status}"
    puts "   ID: #{file.id} | Created: #{file.created_at.strftime('%m/%d/%Y')}"

    # Show associated lessons/resources
    lessons = Learning::ScormLesson.where(training_file: file)
    if lessons.any?
      puts "   Lessons: #{lessons.map(&:title).join(', ')}"
    end

    puts ""
  end

  # Summary and recommendations
  puts "=" * 60
  puts "📋 OPTIMIZATION RECOMMENDATIONS:"
  puts ""

  if timeout_risk.any?
    puts "🚨 URGENT - Files over 500MB (timeout risk): #{timeout_risk.count}"
    puts "   These files may fail to upload or extract"
    puts "   → Immediate optimization required"
    puts ""
  end

  if large_files.any?
    puts "⚠️ Large files over 100MB: #{large_files.count}"
    puts "   These should be optimized for better performance"
    puts "   → Recommend SCORM optimization guide"
    puts ""
  end

  if mobile_issues.any?
    puts "📱 Files over 50MB (mobile performance): #{mobile_issues.count}"
    puts "   May cause issues on mobile devices"
    puts "   → Consider mobile-optimized versions"
    puts ""
  end

  puts "💡 Share SCORM optimization guide with customers who have large files"
  puts "   Focus on video compression and image optimization"

  {
    total: scorm_files.count,
    timeout_risk: timeout_risk.count,
    large_files: large_files.count,
    mobile_issues: mobile_issues.count
  }
end

def find_oversized_scorm_by_customer(customer_name = nil, size_threshold_mb: 100)
  puts "🔍 Finding oversized SCORM files#{customer_name ? " for #{customer_name}" : ""}..."
  puts "Threshold: #{size_threshold_mb}MB"
  puts ""

  # Base query for large SCORM files
  query = Training::File.joins(:attachment)
                       .where(deleted_at: nil)
                       .where(active_storage_blobs: { metadata: { scorm: true } })
                       .where('active_storage_blobs.byte_size > ?', size_threshold_mb.megabytes)
                       .includes(attachment: :blob)

  # Filter by customer if specified
  if customer_name
    # This assumes training files are associated with lessons in courses that have organization context
    # Adjust the query based on your actual data model for customer/organization association
    puts "🚧 Customer filtering not yet implemented - showing all large files"
    puts "   (Customer association logic needs to be added based on your data model)"
    puts ""
  end

  large_files = query.order('active_storage_blobs.byte_size DESC')

  if large_files.empty?
    puts "✅ No SCORM files found over #{size_threshold_mb}MB"
    return []
  end

  puts "Found #{large_files.count} files over #{size_threshold_mb}MB:"
  puts ""

  large_files.each do |file|
    size_mb = file.blob.byte_size / 1.megabyte.to_f

    puts "📁 #{file.filename} - #{size_mb.round(1)}MB"
    puts "   ID: #{file.id}"
    puts "   Created: #{file.created_at.strftime('%m/%d/%Y %H:%M')}"
    puts "   Extracted: #{file.extracted? ? 'Yes' : 'No'}"

    # Find associated lessons
    lessons = Learning::ScormLesson.where(training_file: file)
    if lessons.any?
      lessons.each do |lesson|
        puts "   → Lesson: #{lesson.title} (Course: #{lesson.course.title})"
      end
    else
      puts "   → No associated lessons found"
    end

    # Check for resource library usage
    resources = ResourceLibrary::Resource.where("body ILIKE ?", "%#{file.id}%")
    if resources.any?
      puts "   ⚠️ Also referenced in #{resources.count} ResourceLibrary resources"
    end

    puts ""
  end

  puts "💡 NEXT STEPS:"
  puts "• Share SCORM optimization guide with content creators"
  puts "• Focus on video compression (720p max) and image optimization"
  puts "• Recommend file sizes under 100MB for best performance"

  large_files.to_a
end

def check_scorm_extraction_failures(days_back: 7)
  puts "🔍 Checking for SCORM extraction failures in last #{days_back} days..."
  puts ""

  # Find recent training files that aren't extracted
  recent_files = Training::File.where(deleted_at: nil)
                              .where('created_at > ?', days_back.days.ago)
                              .includes(attachment: :blob)

  failed_extractions = recent_files.select { |f| !f.extracted? && f.scorm? }
  large_unextracted = recent_files.select { |f| !f.extracted? && f.blob.byte_size > 100.megabytes }

  if failed_extractions.empty? && large_unextracted.empty?
    puts "✅ No extraction failures found in last #{days_back} days"
    return
  end

  if failed_extractions.any?
    puts "❌ SCORM files that failed extraction: #{failed_extractions.count}"
    failed_extractions.each do |file|
      size_mb = file.blob.byte_size / 1.megabyte.to_f
      puts "   • #{file.filename} - #{size_mb.round(1)}MB (#{file.created_at.strftime('%m/%d %H:%M')})"
    end
    puts ""
  end

  if large_unextracted.any?
    puts "⚠️ Large files (>100MB) not yet extracted: #{large_unextracted.count}"
    large_unextracted.each do |file|
      size_mb = file.blob.byte_size / 1.megabyte.to_f
      age_hours = ((Time.current - file.created_at) / 1.hour).round(1)
      puts "   • #{file.filename} - #{size_mb.round(1)}MB (#{age_hours}h ago)"
    end
    puts ""
  end

  puts "💡 Large files may timeout during extraction - recommend optimization"

  { failed_extractions: failed_extractions.count, large_unextracted: large_unextracted.count }
end

def scorm_optimization_guide_summary
  puts <<~GUIDE
    📋 SCORM OPTIMIZATION QUICK REFERENCE
    ═══════════════════════════════════════

    🎯 TARGET FILE SIZE: Under 100MB (unless video-heavy)
    🚨 CRITICAL LIMIT: 500MB (may cause timeouts)

    🔍 COMMON BLOAT CAUSES:
    • High-resolution videos not optimized for web
    • Large, uncompressed images
    • Extra fonts or media
    • Unused files bundled into export

    ⚡ OPTIMIZATION STEPS:
    1. Unzip SCORM file and sort by file size
    2. Focus on files larger than 5-10MB (.mp4, .png, .jpg)
    3. Compress videos (target 720p resolution)
    4. Optimize images (use JPEG or compressed PNG)
    5. Remove unused assets

    📦 REPACKAGING:
    • Select all files INSIDE the SCORM folder (not the folder itself)
    • Compress to .zip format
    • Ensure imsmanifest.xml is at root level

    🔧 ZIPLINE LIMITS:
    • Files over 500MB may timeout
    • Always test on mobile devices
    • Contact Support for assistance

    💡 Remember: Light SCORM = Better Experience
  GUIDE
end

# Display cheatsheet on load
scorm_cheatsheet
