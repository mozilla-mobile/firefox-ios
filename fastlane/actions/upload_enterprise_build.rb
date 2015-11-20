require 'fileutils'

module Fastlane
  module Actions
    module SharedValues
      ENTERPRISE_UPLOAD_APP_VERSION = :ENTERPRISE_UPLOAD_APP_VERSION
      ENTERPRISE_UPLOAD_DATESTAMP = :ENTERPRISE_UPLOAD_DATESTAMP
      ENTERPRISE_UPLOAD_BUILD_VERSION = :ENTERPRISE_UPLOAD_BUILD_VERSION
      ENTERPRISE_UPLOAD_BUILD_FLAVOUR = :ENTERPRISE_UPLOAD_BUILD_FLAVOUR
    end

    # To share this integration with the other fastlane users:
    # - Fork https://github.com/KrauseFx/fastlane
    # - Clone the forked repository
    # - Move this integration into lib/fastlane/actions
    # - Commit, push and submit the pull request

    class UploadEnterpriseBuildAction < Action
      # requires plist, html & release notes location, ipa, upload host, upload URL, username, password
      def self.run(params)
        
        app_version = ENV["APP_VERSION"]
        Helper.log.debug "App version: #{app_version}"
        build_version = ENV["BUILD_VERSION"]
        Helper.log.debug "Build version: #{build_version}"
        datestamp = ENV["DATESTAMP"]
        Helper.log.debug "Datestamp: #{datestamp}"
        build_flavour = ENV["BUILD_FLAVOUR"]
        Helper.log.debug "Build flavour: #{build_flavour}"

        # read in plist, html & release notes files
        Helper.log.info "Reading in plist #{params[:plist]}"
        plist = ""
        File.open(params[:plist], "r") do |f|
          f.each_line do |line|
            plist += line
          end
        end

        Helper.log.info "Reading in html #{params[:html]}"
        html = ""
        File.open(params[:html], "r") do |f|
          f.each_line do |line|
            html += line
          end
        end

        Helper.log.info "Reading in notes #{params[:release_notes]}"
        notes = ""
        File.open(params[:release_notes], "r") do |f|
          f.each_line do |line|
            notes += line
          end
        end

        Helper.log.debug "build_flavour #{build_flavour}"
        # replace BUILDID, BUILDNAME, DATESTAMP, REVISION, BUILDSCHEME, NOTES
        # with APP_VERSION(BUILD_VERSION), BUILD_NAME, DATESTAMP, BUILD_VERSION, lane_context[SharedValues::LANE_NAME], release_notes
        # in plist & html files

        plist.gsub! 'BUILDID', app_version
        plist.gsub! 'BUILDNAME', params[:build_name]
        plist.gsub! 'DATESTAMP', datestamp
        plist.gsub! 'REVISION', build_version
        plist.gsub! 'BUILDSCHEME', build_flavour
        Helper.log.debug "#{plist}"

        html.gsub! 'BUILDID', app_version
        html.gsub! 'BUILDNAME', params[:build_name]
        html.gsub! 'DATESTAMP', datestamp
        html.gsub! 'REVISION', build_version
        html.gsub! 'BUILDSCHEME', build_flavour
        html.gsub! 'NOTES', notes
        Helper.log.debug "#{html}"

        # save copies into ASSETS dir
        Helper.log.info "Saving to assets dir"
        assets_dir = "assets/#{params[:build_name]}"
        FileUtils::mkdir_p assets_dir unless File.exists?(assets_dir)

        plist_file_name = "#{params[:build_name]}.plist"
        html_file_name = "#{params[:build_name]}.html"

        File.open("#{assets_dir}/#{plist_file_name}", 'w') {|f| f.write(plist) }
        File.open("#{assets_dir}/#{html_file_name}", 'w') {|f| f.write(html) }
        Helper.log.info "Plist & HTML files written to assets dir"

        # log into upload_url with username and password
        # upload ipa, plist & html files to upload_url
        Helper.log.info "Uploading to #{params[:host]}:#{params[:upload_location]}"
        command = "scp #{assets_dir}/#{html_file_name} #{params[:host]}:#{params[:upload_location]}/#{html_file_name} || exit 1\n \
scp #{assets_dir}/#{html_file_name} #{params[:host]}:#{params[:upload_location]}/#{plist_file_name} || exit 1\n \
scp builds/#{params[:build_name]}.ipa #{params[:host]}:#{params[:upload_location]}/builds/#{params[:build_name]}.ipa || exit 1\n \
scp builds/#{params[:build_name]}.app.dSYM.zip #{params[:host]}:#{params[:upload_location]}/builds/#{params[:build_name]}.app.dSYM.zip || exit 1\n \

ssh #{params[:host]} 'ln -sf /home/iosbuilds/#{plist_file_name} #{params[:upload_location]}/#{build_flavour}.plist'|| exit 1\n \
ssh #{params[:host]} 'ln -sf /home/iosbuilds/#{html_file_name} #{params[:upload_location]}/#{build_flavour}.html' || exit 1"

        Helper.log.debug "Executing: #{command}"
        #sh(command)
        Helper.log.info "Successfully uploaded enterprise build "
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Upload an enterprise ipa, dsym, plist and HTML to a remote location"
      end

      def self.details
        # Optional:
        # this is your change to provide a more detailed description of this action
        "Takes in a plist & html template and uses it to create a set of resources for uploading to specified remote location set up for enterprise download"
      end

      def self.available_options
        # Define all options your action supports. 
        
        # Below a few examples
        [
          FastlaneCore::ConfigItem.new(key: :plist,
                                       env_name: "FL_UPLOAD_ENTERPRISE_BUILD_PLIST_LOCATION", # The name of the environment variable
                                       description: "Location for plist template", # a short description of this parameter
                                       verify_block: proc do |value|
                                          raise "No plist template location provided, pass using `plist: 'location'`".red unless (value and not value.empty?)
                                          # raise "Couldn't find file at path '#{value}'".red unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :html,
                                       env_name: "FL_UPLOAD_ENTERPRISE_BUILD_HTML_LOCATION", # The name of the environment variable
                                       description: "Location for HTML template", # a short description of this parameter
                                       verify_block: proc do |value|
                                          raise "No HTML template location provided, pass using `html: 'location'`".red unless (value and not value.empty?)
                                          # raise "Couldn't find file at path '#{value}'".red unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :release_notes,
                                       env_name: "FL_UPLOAD_ENTERPRISE_BUILD_RELEASE_NOTES_LOCATION", # The name of the environment variable
                                       description: "Location for release notes", # a short description of this parameter
                                       verify_block: proc do |value|
                                          raise "No release notes location provided, pass using `release_notes: 'location'`".red unless (value and not value.empty?)
                                          # raise "Couldn't find file at path '#{value}'".red unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :build_name,
                                       env_name: "FL_UPLOAD_ENTERPRISE_BUILD_NAME", # The name of the environment variable
                                       description: "Name of the build to upload", # a short description of this parameter
                                       verify_block: proc do |value|
                                          raise "No build name provided, pass using `build_name: 'name'`".red unless (value and not value.empty?)
                                          # raise "Couldn't find file at path '#{value}'".red unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :host,
                                       env_name: "FL_UPLOAD_ENTERPRISE_BUILD_UPLOAD_HOST", # The name of the environment variable
                                       description: "Host to upload files to", # a short description of this parameter
                                       verify_block: proc do |value|
                                          raise "No upload host provided, pass using `host: 'host'`".red unless (value and not value.empty?)
                                          # raise "Couldn't find file at path '#{value}'".red unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :upload_location,
                                       env_name: "FL_UPLOAD_ENTERPRISE_BUILD_UPLOAD_LOCATION", # The name of the environment variable
                                       description: "File path to upload files to", # a short description of this parameter
                                       verify_block: proc do |value|
                                          raise "No upload location provided, pass using `upload_location: 'filepath'`".red unless (value and not value.empty?)
                                          # raise "Couldn't find file at path '#{value}'".red unless File.exist?(value)
                                       end),
        ]
      end

      def self.output
      end

      def self.return_value
        # If you method provides a return value, you can describe here what it does
      end

      def self.authors
        # So no one will ever forget your contribution to fastlane :) You are awesome btw!
        ["mozilla"]
      end

      def self.is_supported?(platform)
        platform == :ios
      end
    end
  end
end
