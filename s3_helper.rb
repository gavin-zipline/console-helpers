# S3 Helper for Rails Console
# ---------------------------
# Provides a simple way to upload text content (e.g., CSV) to environment-specific S3 buckets
# via the `put_to_s3(path, content)` method.
# Buckets are selected based on Rails.env and uploads return a public URL.
#
# ⚠️ Note: This helper is intended for plain text uploads only (CSV, plain text, etc.).
# It does not currently support setting content-type headers for binary files or formatted documents.

S3_HELPER_VERSION = "0.1.7"

def current_s3_bucket
  case Rails.env
  when "production" then "cdn-retailzipline-com"
  when "staging"    then "cdn-retailzipline-xyz"
  else                   "cdn-retailzipline-dev"
  end
end

class S3Uploader
  def initialize(key, data, bucket: current_s3_bucket)
    @key = key
    @data = data
    @bucket = bucket
  end

  def upload
    puts("> Uploading to S3")
    s3_object.put(body: @data, content_disposition: 'attachment')
    s3_object.presigned_url(:get, expires_in: 3600)
  end

  private

  def s3_object
    Aws::S3::Object.new(client: client, key: @key, bucket_name: @bucket)
  end

  def client
    @client ||= Aws::S3::Client.new
  end
end

def put_to_s3(path, content)
  path = "tmp/16561/#{path}" unless path.start_with?("tmp/16561/")
  url = S3Uploader.new(path, content).upload
  puts "✅ Upload complete: #{url}"
  url
end

def get_s3_url(object, filename = nil)
  key = case object
        when ActiveStorage::Blob
          object.key
        when Learning::ScormLesson
          object.attachment&.blob&.key
        else
          object.try(:attachment)&.try(:blob)&.try(:key)
        end

  if key.blank?
    puts "⚠️ No S3 key found for object: #{object.inspect}"
    return
  end

  bucket = current_s3_bucket
  region = "us-east-1"
  url = "https://#{bucket}.s3.#{region}.amazonaws.com/#{key}"
  name = filename || File.basename(key)

  puts "🧾 #{name}"
  puts url
  puts "📤 aws s3 cp #{name} s3://#{bucket}/#{key} --region #{region}"
  url
end

def scorm_blob_url(blob)
  return nil unless blob
  "https://cdn-retailzipline-com.s3.us-east-1.amazonaws.com/#{blob.key}"
end

def s3_helper_cheatsheet
  puts   "\n🚀🚀🚀 S3 HELPER — VERSION #{S3_HELPER_VERSION} 🚀🚀🚀"
  puts "\n📘 Cheatsheet:"
  puts "- put_to_s3(path, content)"
  puts "  Uploads plain text (e.g., CSV) to an S3 bucket and returns a public URL."
  puts "  Bucket is chosen based on Rails.env:"
  puts "    - production → cdn-retailzipline-com"
  puts "    - staging    → cdn-retailzipline-xyz"
  puts "    - otherwise  → cdn-retailzipline-dev"
  puts "  All paths are prefixed with tmp/16561/ unless already present."
  puts ""
  puts "🧪 Example:"
  puts "  csv = <<~CSV"
  puts "    id,name,email"
  puts "    1,Alice,alice@example.com"
  puts "    2,Bob,bob@example.com"
  puts "    3,Charlie,charlie@example.com"
  puts "  CSV"
  puts ""
  puts "  filename = \"test_users_\#{Time.now.to_i}.csv\""
  puts "  url = put_to_s3(filename, csv)"
  puts "  puts url  # => public S3 URL to the uploaded CSV"
  puts ""
  puts "⚠️ Only supports plain text (CSV, TXT). No binary uploads or content-type headers.\n"
  puts
  puts "🔄 SCORM Environment Sync:"
  puts "- get_scorm_file(resource_or_lesson)"
  puts "  Downloads SCORM content from ResourceLibrary::Resource or Learning::ScormLesson."
  puts "  Use this to copy SCORM files from production to staging for testing."
  puts ""
  puts "- put_scorm_file(lesson, scorm_data)"
  puts "  Uploads SCORM content to a Learning::ScormLesson in current environment."
  puts "  Use this to test SCORM files in staging before customer deployment."
  puts ""
  puts "🧪 SCORM Sync Example:"
  puts "  # In production console - get SCORM data"
  puts "  lesson = Learning::ScormLesson.find(12345)"
  puts "  scorm_data = get_scorm_file(lesson)"
  puts ""
  puts "  # In staging console - upload SCORM data"
  puts "  staging_lesson = Learning::ScormLesson.find(67890)"
  puts "  put_scorm_file(staging_lesson, scorm_data)"
  puts ""
end

s3_helper_cheatsheet

# SCORM Environment Sync Functions
# ================================
# Since SCORM files aren't propagated to staging, these functions help
# copy SCORM content between environments for testing and debugging

def get_scorm_file(resource_or_lesson)
  case resource_or_lesson
  when ResourceLibrary::Resource
    get_scorm_from_resource(resource_or_lesson)
  when Learning::ScormLesson
    get_scorm_from_lesson(resource_or_lesson)
  else
    puts "❌ Invalid object type. Expected ResourceLibrary::Resource or Learning::ScormLesson"
    nil
  end
end

def put_scorm_file(resource_or_lesson, scorm_data)
  case resource_or_lesson
  when ResourceLibrary::Resource
    put_scorm_to_resource(resource_or_lesson, scorm_data)
  when Learning::ScormLesson
    put_scorm_to_lesson(resource_or_lesson, scorm_data)
  else
    puts "❌ Invalid object type. Expected ResourceLibrary::Resource or Learning::ScormLesson"
    nil
  end
end

private

def get_scorm_from_resource(resource)
  puts "🔍 Extracting SCORM data from ResourceLibrary::Resource..."
  
  # Find training file IDs in the resource body
  training_file_ids = resource.body.to_s.scan(/([a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12})/).flatten.uniq
  
  if training_file_ids.empty?
    puts "❌ No training file IDs found in resource body"
    return nil
  end
  
  training_file_id = training_file_ids.first
  training_file = Training::File.find_by(id: training_file_id)
  
  if training_file.nil?
    puts "❌ Training file not found: #{training_file_id}"
    return nil
  end
  
  download_scorm_content(training_file)
end

def get_scorm_from_lesson(lesson)
  puts "🔍 Extracting SCORM data from Learning::ScormLesson..."
  
  if lesson.training_file.nil?
    puts "❌ No training file associated with lesson"
    return nil
  end
  
  download_scorm_content(lesson.training_file)
end

def download_scorm_content(training_file)
  puts "📥 Downloading SCORM content from training file: #{training_file.filename}"
  
  if !training_file.extracted?
    puts "⚠️ Training file not extracted yet"
    return nil
  end
  
  # Download the original SCORM zip if available
  if training_file.attachment.attached?
    blob = training_file.attachment.blob
    puts "✅ Found original SCORM file: #{blob.filename} (#{(blob.byte_size / 1.megabyte.to_f).round(1)}MB)"
    
    # Return blob data for upload to other environment
    {
      filename: blob.filename.to_s,
      content_type: blob.content_type,
      byte_size: blob.byte_size,
      blob: blob,
      training_file_id: training_file.id,
      metadata: {
        extracted: training_file.extracted?,
        scorm: training_file.scorm?,
        s3_url: training_file.s3_url
      }
    }
  else
    puts "❌ No attachment found for training file"
    nil
  end
end

def put_scorm_to_resource(_resource, _scorm_data)
  puts "❌ Uploading SCORM to ResourceLibrary::Resource not supported"
  puts "💡 Use Learning::ScormLesson for proper SCORM integration"
  nil
end

def put_scorm_to_lesson(lesson, scorm_data)
  puts "📤 Uploading SCORM content to Learning::ScormLesson..."
  
  if scorm_data.nil? || !scorm_data[:blob]
    puts "❌ Invalid SCORM data provided"
    return nil
  end
  
  begin
    # Create new training file in current environment
    new_training_file = Training::File.new(filename: scorm_data[:filename])
    
    # Attach the blob content
    new_training_file.attachment.attach(
      io: StringIO.new(scorm_data[:blob].download),
      filename: scorm_data[:filename],
      content_type: scorm_data[:content_type]
    )
    
    # Save and trigger extraction
    if new_training_file.save
      lesson.update!(training_file: new_training_file)
      
      puts "✅ SCORM file uploaded successfully"
      puts "   New training file ID: #{new_training_file.id}"
      puts "   Original size: #{(scorm_data[:byte_size] / 1.megabyte.to_f).round(1)}MB"
      puts "   Extraction will begin automatically"
      
      new_training_file
    else
      puts "❌ Failed to save training file: #{new_training_file.errors.full_messages.join(', ')}"
      nil
    end
  rescue => e
    puts "❌ Error uploading SCORM: #{e.message}"
    nil
  end
end
