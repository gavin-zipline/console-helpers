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
end

s3_helper_cheatsheet
