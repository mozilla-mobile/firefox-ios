module Fastlane
  module Actions
    module SharedValues
      CHECKOUT_GIT_BRANCH_CUSTOM_VALUE = :CHECKOUT_GIT_BRANCH_CUSTOM_VALUE
    end

    # To share this integration with the other fastlane users:
    # - Fork https://github.com/KrauseFx/fastlane
    # - Clone the forked repository
    # - Move this integration into lib/fastlane/actions
    # - Commit, push and submit the pull request

    class CheckoutGitBranchAction < Action
      def self.run(params)
        # fastlane will take care of reading in the parameter and fetching the environment variable:
        Helper.log.info "Branch Name: #{params[:branch]}"
        Helper.log.info "Branch From: #{params[:base_branch]}"

        if not params[:base_branch].empty?
          sh("git checkout '#{params[:base_branch]}' || exit 1")
        end
        sh("git checkout '#{params[:branch]}' || git checkout -b '#{params[:branch]}' || exit 1")
     
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Checks out the given branch. If the branch doesn't exist it will create the branch."
      end

      def self.details
        # Optional:
        # this is your change to provide a more detailed description of this action
        "Checks out the given branch. If the branch doesn't exist it will create the branch. "\
        "If a base_branch is specified then it will create the branch of the provided base branch, "\
        "otherwise the branch will be created from master"
      end

      def self.available_options
        # Define all options your action supports. 
        
        # Below a few examples
        [
          FastlaneCore::ConfigItem.new(key: :branch,
                                       env_name: "FL_CHECKOUT_GIT_BRANCH_NAME", # The name of the environment variable
                                       description: "The name of the branch to check out", # a short description of this parameter),
                                       is_string: true,
                                       verify_block: proc do |value|
                                          raise "No branch name to check out has been provided".red unless (value and not value.empty?)
                                       end),
          FastlaneCore::ConfigItem.new(key: :base_branch,
                                       env_name: "FL_CHECKOUT_GIT_BRANCH_BASE",
                                       description: "The name of the branch to branch from if creating a new branch",
                                       is_string: true, # true: verifies the input is a string, false: every kind of value
                                       default_value: "master") # the default value if the user didn't provide one
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
