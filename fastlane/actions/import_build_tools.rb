module Fastlane
  module Actions
    module SharedValues
    end

    # To share this integration with the other fastlane users:
    # - Fork https://github.com/KrauseFx/fastlane
    # - Clone the forked repository
    # - Move this integration into lib/fastlane/actions
    # - Commit, push and submit the pull request

    class ImportBuildToolsAction < Action
      def self.run(params)
        # fastlane will take care of reading in the parameter and fetching the environment variable:
        Helper.log.info "Parameter URL: #{params[:url]}"
        Helper.log.info "Parameter Clone Folder: #{params[:clone_folder]}"
        Helper.log.info "Parameter Branch: #{params[:branch]}"

        #import from git into subdir
        branch_option = ""
        branch_option = "--branch #{params[:branch]}" if params[:branch] != 'HEAD'

        clone_command = "git clone '#{params[:url]}' '#{params[:clone_folder]}' #{branch_option}"
        Actions.sh(clone_command)
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "A short description with <= 80 characters of what this action does"
      end

      def self.details
        # Optional:
        # this is your change to provide a more detailed description of this action
        "You can use this action to do cool things..."
      end

      def self.available_options
        # Define all options your action supports. 
        
        # Below a few examples
        [
          FastlaneCore::ConfigItem.new(key: :url,
                                       env_name: "FL_IMPORT_BUILD_TOOLS_URL", # The name of the environment variable
                                       description: "URL of github repository that contains build tools", # a short description of this parameter
                                       verify_block: proc do |value|
                                          raise "No URL for ImportBuildToolsAction given, pass using `url: 'value'`".red unless (value and not value.empty?)
                                          # raise "Couldn't find file at path '#{value}'".red unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :clone_folder,
                                       env_name: "FL_IMPORT_BUILD_TOOLS_CLONE_FOLDER", # The name of the environment variable
                                       description: "path to import build tools to", # a short description of this parameter
                                       verify_block: proc do |value|
                                          raise "No Clone folder for ImportBuildToolsAction given, pass using `clone_folder: 'path'`".red unless (value and not value.empty?)
                                          # raise "Couldn't find file at path '#{value}'".red unless File.exist?(value)
                                       end),
          FastlaneCore::ConfigItem.new(key: :branch,
                                       env_name: "FL_IMPORT_BUILD_TOOLS_BRANCH",
                                       description: "Branch of build tools to import",
                                       default_value: "HEAD") # the default value if the user didn't provide one
        ]
      end

      def self.output
      end

      def self.return_value
        # If you method provides a return value, you can describe here what it does
      end

      def self.authors
        # So no one will ever forget your contribution to fastlane :) You are awesome btw!
        ["Your GitHub/Twitter Name"]
      end

      def self.is_supported?(platform)
        # you can do things like
        # 
        #  true
        # 
        #  platform == :ios
        # 
        #  [:ios, :mac].include?(platform)
        # 

        platform == :ios
      end
    end
  end
end
