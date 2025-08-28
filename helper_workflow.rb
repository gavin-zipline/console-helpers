#!/usr/bin/env ruby
# ------------------------------------------------------------------------------
# Console Helper Workflow - Deployment System
# ------------------------------------------------------------------------------
# Purpose: Manage Rails console helpers with GitHub Gist deployment
#
# Architecture: Local Development → GitHub Gist → Remote Rails Console (hrc)
#
# Usage: ruby helper_workflow.rb [command] [options]

require 'fileutils'
require 'optparse'

class HelperWorkflow
  HELPER_VERSION = "2.0.0"

  def initialize
    @console_helpers_dir = File.dirname(__FILE__)
    # We're already in the console-helpers directory
  end

  def sync_to_gist
    puts "🔄 Syncing helpers to Gist (remote console source)..."
    
    validate_directory
    helper_files = Dir.glob(File.join(@console_helpers_dir, '*_helper.rb'))

    helper_files.each do |file|
      basename = File.basename(file)
      puts "  ✅ #{basename} ready for Gist deployment"
    end

    puts "✅ #{helper_files.size} helpers ready for remote Rails console"
    puts "💡 Next: Run 'deploy' to push to Gist"
  end

  def validate_helpers
    puts "🔍 Validating helper compliance..."
    
    validate_directory
    helper_files = Dir.glob(File.join(@console_helpers_dir, '*_helper.rb'))
    issues = []

    helper_files.each do |file|
      basename = File.basename(file, '.rb')
      content = File.read(file)

      # Check for version constant
      unless content.match(/#{basename.upcase.gsub('_HELPER', '')}_HELPER_VERSION\s*=/)
        issues << "#{basename}: Missing version constant"
      end

      # Check for cheatsheet method
      unless content.match(/def #{basename}_cheatsheet/)
        issues << "#{basename}: Missing cheatsheet method"
      end

      # Check for proper header
      unless content.match(/^# -{10,}/)
        issues << "#{basename}: Missing standard header"
      end
    end

    if issues.empty?
      puts "✅ All #{helper_files.size} helpers pass validation"
    else
      puts "⚠️ Found #{issues.size} issues:"
      issues.each { |issue| puts "  • #{issue}" }
    end

    issues.empty?
  end

  def deploy
    puts "🚀 Deploying helpers to Gist for remote console access..."

    validate_directory
    return unless validate_helpers

    commit_message = "Update helpers - #{Time.now.strftime('%Y-%m-%d %H:%M')}"
    deploy_script = File.join(@console_helpers_dir, 'deploy_to_gist.sh')

    if File.exist?(deploy_script)
      puts "📡 Running git deployment script..."
      success = system("cd #{@console_helpers_dir} && #{deploy_script} '#{commit_message}'")
      return success
    else
      puts "💡 Running git commands..."
      Dir.chdir(@console_helpers_dir) do
        system("git add *_helper.rb *.md HELPER_TEMPLATE*.rb")
        system("git commit -m '#{commit_message}' || echo 'No changes to commit'")
        
        puts "🌐 Pushing to Gist (remote console source)..."
        success = system("git push")

        if success
          puts "✅ Successfully deployed to Gist!"
          puts "🎯 Remote console usage: gh(\"helper_name\") in hrc"
        else
          puts "❌ Deploy failed - check git status"
        end

        return success
      end
    end
  end

  def create_helper(name)
    puts "✨ Creating new helper: #{name}"

    validate_directory
    helper_name = name.downcase.gsub(/[^a-z0-9_]/, '_')
    helper_name = "#{helper_name}_helper" unless helper_name.end_with?('_helper')

    template_path = File.join(@console_helpers_dir, 'HELPER_TEMPLATE_EXAMPLE.rb')
    unless File.exist?(template_path)
      puts "❌ Template file not found: #{template_path}"
      puts "💡 Create a template file first or run from console-helpers directory"
      return
    end

    template = File.read(template_path)
    
    # Replace template placeholders
    constant_name = helper_name.upcase.gsub('_HELPER', '')
    display_name = name.split(/[_\s]/).map(&:capitalize).join(' ')

    new_content = template.gsub(/EXAMPLE_HELPER_VERSION/, "#{constant_name}_HELPER_VERSION")
                         .gsub(/example_helper_cheatsheet/, "#{helper_name}_cheatsheet") 
                         .gsub(/EXAMPLE HELPER/, "#{display_name.upcase} HELPER")
                         .gsub(/Example Helper/, display_name)
                         .gsub(/find_example_record/, "find_#{helper_name.gsub('_helper', '')}")
                         .gsub(/example_records_summary/, "#{helper_name.gsub('_helper', '')}s_summary")
                         .gsub(/eh_version/, "#{helper_name.gsub('_helper', '')}_version")

    new_file_path = File.join(@console_helpers_dir, "#{helper_name}.rb")

    if File.exist?(new_file_path)
      puts "⚠️ Helper already exists: #{new_file_path}"
      print "Overwrite? (y/N): "
      return unless gets.chomp.downcase == 'y'
    end

    File.write(new_file_path, new_content)
    puts "✅ Created: #{new_file_path}"
    puts "💡 Next steps:"
    puts "   1. Edit the helper for your specific use case"
    puts "   2. Test locally if possible"
    puts "   3. Deploy: ruby helper_workflow.rb deploy"
    puts "   4. Test in remote console: gh(\"#{helper_name.gsub('_helper', '')}\")"
  end

  def status
    puts "📊 Console Helper System Status:"
    puts ""

    validate_directory
    helper_files = Dir.glob(File.join(@console_helpers_dir, '*_helper.rb')).map { |f| File.basename(f) }.sort

    puts "📁 Location: #{@console_helpers_dir}"
    puts "📦 Helper files: #{helper_files.size}"
    
    unless helper_files.empty?
      puts ""
      puts "🔧 Available Helpers:"
      helper_files.each { |file| puts "  • #{file}" }
    end

    puts ""
    puts "🎯 Remote Console Access:"
    puts "  • Deploy to make helpers available in hrc"
    puts "  • Usage in remote Rails console: gh(\"helper_name\")"

    puts ""
    puts "🔧 Available Commands:"
    puts "  • sync         → Prepare helpers for deployment"
    puts "  • validate     → Check helper compliance"  
    puts "  • deploy       → Push to Gist for remote access"
    puts "  • create NAME  → Create new helper from template"
    puts "  • status       → Show this status"
  end

  def run(command, *args)
    case command
    when 'sync'
      sync_to_gist
    when 'validate'
      validate_helpers
    when 'deploy'
      deploy
    when 'create'
      if args.empty?
        puts "❌ Usage: ruby helper_workflow.rb create HELPER_NAME"
      else
        create_helper(args.first)
      end
    when 'status', nil
      status
    else
      puts "❌ Unknown command: #{command}"
      status
    end
  end

  private

  def validate_directory
    unless Dir.exist?(@console_helpers_dir)
      puts "❌ Console helpers directory not found: #{@console_helpers_dir}"
      puts "💡 Make sure you're running from the console-helpers repo or have it adjacent"
      exit 1
    end
  end
end

# Command line interface
if __FILE__ == $0
  workflow = HelperWorkflow.new
  workflow.run(*ARGV)
end
