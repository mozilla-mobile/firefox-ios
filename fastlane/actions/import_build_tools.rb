module Fastlane
  module Actions

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
        "Downloads an Git repo to a given location"
      end

      def self.details
        "Downloads a Git repo <:url> to a given location <:clone_folder> and checks out a specific branch if <:branch> is provided"
      end

      def self.available_options
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

      def self.authors
        ["Mozilla"]
      end

      def self.is_supported?(platform)
        platform == :ios
      end
    end
  end
end
