# frozen_string_literal: true

#
#  Copyright 2017 Google Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

require 'colored'
require 'fileutils'
require 'xcodeproj'

def configure_for_earlgrey(*_)
  EarlGrey.puts_yellow <<-S
    configure_for_earlgrey in post_install is now deprecated, you should safely remove it now.
    EarlGrey pod will automatically set up your project and schemes.

    for more information, please visit our installation guideline:
    https://github.com/google/EarlGrey/blob/master/docs/install-and-run.md
    S
end

module EarlGrey
  XCScheme = Xcodeproj::XCScheme
  EnvironmentVariable = XCScheme::EnvironmentVariable

  XCSCHEME_EXT = '*.xcscheme'.freeze
  ENVIRONMENT_KEY = 'DYLD_INSERT_LIBRARIES'.freeze
  ENVIRONMENT_VALUE = '@executable_path/EarlGrey.framework/EarlGrey'.freeze

  FRAMEWORK_SEARCH_PATHS = 'FRAMEWORK_SEARCH_PATHS'.freeze
  HEADER_SEARCH_PATHS = 'HEADER_SEARCH_PATHS'.freeze

  SWIFT_FILETYPE = 'sourcecode.swift'.freeze
  UNITTEST_PRODUCTTYPE = 'com.apple.product-type.bundle.unit-test'.freeze

  CARTHAGE_BUILD_IOS = '$(SRCROOT)/Carthage/Build/iOS'.freeze
  CARTHAGE_HEADERS_IOS = '$(SRCROOT)/Carthage/Build/iOS/**'.freeze

  EARLGREY_FRAMEWORK = 'EarlGrey.framework'.freeze
  CARTHAGE_FRAMEWORK_PATH =
    'Carthage/Build/iOS/EarlGrey.framework'.freeze
  POD_FRAMEWORK_PATH =
    'Pods/EarlGrey/EarlGrey/EarlGrey.framework'.freeze

  class << self
    attr_reader :project_name, :installer, :test_target, :test_target_name,
                :scheme_file, :user_project, :carthage, :swift, :swift_version

    # Returns path to Xcode file, prepending current working dir if necessary.
    # @param [String] project_name name of the .xcodeproj file
    # @param [String] ext xcode file extension
    # @return [String] path to Xcode file
    def path_for(project_name, ext)
      ext_match = File.extname(project_name) == ext
      return project_name if File.exist?(project_name) && ext_match
      path = File.join(dir_path, File.basename(project_name, '.*') + ext)
      path ? path : nil
    end

    # Returns the project's directory. If CocoaPods hasn't had it passed in,
    # then the current directory is chosen.
    # @return [String] directory path for the Xcode project
    def dir_path
      installer ? installer.config.installation_root : Dir.pwd
    end

    # Strips each line in a string
    # @param [String] string the string to process
    # @return [String] the modified string
    def strip(string)
      string.split("\n").map(&:strip).join("\n")
    end

    # Raise error message after removing excessive spaces.
    # @param [String] message the message to raise
    # @return [nil]
    def error(message)
      raise strip(message)
    end

    # Prints string as magenta after stripping excess spacing
    # @param [String] string the string to print
    # @return [nil]
    def puts_magenta(string)
      puts strip(string).magenta
    end

    # Prints string as yellow after stripping excess spacing
    # @param [String] string the string to print
    # @return [nil]
    def puts_yellow(string)
      puts strip(string).yellow
    end

    def set_defaults(project_name, test_target_name, scheme_file, opts = {})
      @swift = opts.fetch(:swift, false)
      @carthage = opts.fetch(:carthage, false)
      @swift_version = opts.fetch(:swift_version, '4.0')

      puts_magenta "Checking and Updating #{project_name} for EarlGrey."
      project_file = path_for project_name, '.xcodeproj'

      raise 'No test target provided' unless test_target_name

      if project_file.nil?
        error <<-E
          The target's xcodeproj file could not be found. Please check if the
          correct PROJECT_NAME is being passed in the Podfile.
          Current PROJECT_NAME is: #{project_name}
        E
      end

      @project_name = project_name
      @test_target_name = test_target_name
      @scheme_file = File.basename(scheme_file, '.*') + '.xcscheme'
      @user_project = Xcodeproj::Project.open(project_file)
      all_targets = user_project.targets
      @test_target = all_targets.find { |target| target.name == test_target_name }
      unless test_target
        error <<-E
          Unable to find target: #{test_target_name}.
          Targets are: #{all_targets.map(&:name)}
        E
      end
    end

    # Main entry point. Configures An Xcode project for use with EarlGrey.
    #
    # @param [String] project_name
    #        the xcodeproj file name
    # @param [String] test_target_name
    #        the test target name contained in xcodeproj
    # @param [String] scheme_file
    #        the scheme file name. defaults to project name when nil.
    # @return [nil]
    def configure_for_earlgrey(project_name, test_target_name,
                               scheme_file, opts = {})
      set_defaults(project_name, test_target_name, scheme_file, opts)

      # Add DYLD_INSERT_LIBRARIES to the schemes
      # rubocop:disable Performance/HashEachMethods
      modify_scheme_for_actions(user_project, [test_target]).each do |_, scheme|
        scheme.save!
      end
      # rubocop:enable Performance/HashEachMethods

      # Add a Copy Files Build Phase for EarlGrey.framework to embed it into
      # the app under test.
      framework_ref = add_earlgrey_product user_project, carthage
      add_earlgrey_framework test_target, framework_ref
      add_earlgrey_copy_files_script test_target, framework_ref

      # Add header/framework search paths for carthage
      add_carthage_search_paths test_target if carthage

      # Adds EarlGrey.swift
      copy_swift_files(user_project, test_target, swift_version) if swift

      user_project.save
      puts_magenta <<-S
        EarlGrey setup complete.
        You can use the Test Target: #{test_target_name} for EarlGrey testing.
      S
    end

    # Returns the schemes that contain the given targets
    #
    # @param [Xcodeproj::Project] project
    # @param [Array<Xcodeproj::PBXNativeTarget>] targets
    # @return [Array<Xcodeproj::XCScheme>]
    def schemes_for_native_targets(project, targets)
      schemes = Dir[File.join(XCScheme.shared_data_dir(project.path), XCSCHEME_EXT)] +
                Dir[File.join(XCScheme.user_data_dir(project.path), XCSCHEME_EXT)]

      schemes = schemes.map { |scheme| [scheme, Xcodeproj::XCScheme.new(scheme)] }

      targets_names = targets.map(&:name)
      schemes.select do |scheme|
        scheme[1].test_action.testables.any? do |testable|
          testable.buildable_references.any? do |buildable|
            targets_names.include? buildable.target_name
          end
        end
      end
    end

    # Add DYLD_INSERT_LIBRARIES to the launching environments for the test
    # schemes to ensure that EarlGrey is correctly loaded before main() is
    # called.
    #
    # @param [Xcodeproj::Project] project
    # @param [Array<Xcodeproj::PBXNativeTarget>] targets
    # @return [Array<String, Xcodeproj::XCScheme>]
    def modify_scheme_for_actions(project, targets)
      schemes = schemes_for_native_targets(project, targets).uniq do |name, _|
        name
      end
      schemes.each do |name, scheme|
        add_environment_variables_to_test_scheme(name, scheme)
      end
    end

    # Load the EarlGrey framework when the app binary is loaded by
    # the dynamic loader, before the main() method is called.
    #
    # @param [String] name
    # @param [Xcodeproj::XCScheme] scheme
    def add_environment_variables_to_test_scheme(name, scheme)
      name = File.basename(name, '.xcscheme')
      test_action = scheme.test_action
      test_variables = test_action.environment_variables

      # If any environment variables or arguments were being used in the test
      # action by being copied from the launch (run) action then copy them over
      # to the test action along with the EarlGrey environment variable.
      if test_action.should_use_launch_scheme_args_env?
        scheme.launch_action.environment_variables.all_variables.each do |var|
          test_variables.assign_variable var
        end
      end

      env_variable = test_variables[ENVIRONMENT_KEY] ||
                     EnvironmentVariable.new(key: ENVIRONMENT_KEY, value: '')
      if env_variable.value.include? ENVIRONMENT_VALUE
        puts_magenta <<-S
          DYLD_INSERT_LIBRARIES is already set up for #{name}, ignored.
        S
        return scheme
      end
      puts_magenta <<-S
        Adding EarlGrey Framework Location as an Environment Variable
        in the App Project's Test Target's Scheme Test Action #{name}.
      S

      test_action.should_use_launch_scheme_args_env = false
      env_variable.value += env_variable.value.empty? ? '' : ':'
      env_variable.value += ENVIRONMENT_VALUE
      env_variable.enabled = true
      test_variables.assign_variable env_variable
      test_action.environment_variables = test_variables

      scheme.save!
    end

    # Adds EarlGrey.framework to products group. Returns file ref.
    #
    # @param [Xcodeproj::Project] project
    #        the xcodeproject that the app is in, and EarlGrey.framework will
    #        be added to.
    # @param [Boolean] carthage
    #        if the project is carthage
    def add_earlgrey_product(project, carthage)
      framework_path = if carthage
                         CARTHAGE_FRAMEWORK_PATH
                       else
                         POD_FRAMEWORK_PATH
                       end

      framework_ref = project.frameworks_group.files.find do |f|
        # TODO: should have some md5 check on the actual binary
        f.path == framework_path
      end
      unless framework_ref
        framework_ref = project.frameworks_group.new_file(framework_path)
        framework_ref.source_tree = 'SOURCE_ROOT'
      end
      framework_ref
    end

    # Generates a copy files build phase to embed the EarlGrey framework into
    # the app under test.
    #
    # @param [PBXNativeTarget] target
    #        the native target to add a copy script that copies the earlgrey
    #        framework into its host app
    # @param [PBXFileReference] framework_ref
    #        the framework reference pointing to the EarlGrey.framework
    def add_earlgrey_copy_files_script(target, framework_ref)
      earlgrey_copy_files_phase_name = 'EarlGrey Copy Files'
      return true if target.copy_files_build_phases.any? do |copy_files_phase|
        copy_files_phase.name == earlgrey_copy_files_phase_name
      end

      return false unless target.product_type.eql? UNITTEST_PRODUCTTYPE
      new_copy_files_phase = target.new_copy_files_build_phase(earlgrey_copy_files_phase_name)
      new_copy_files_phase.dst_path = '$(TEST_HOST)/../'
      new_copy_files_phase.dst_subfolder_spec = '0'

      build_file = new_copy_files_phase.add_file_reference framework_ref, true
      build_file.settings = { 'ATTRIBUTES' => ['CodeSignOnCopy'] }
      build_file
    end

    # Updates test target's build configuration framework and header search
    # paths for carthage. Generates a copy files build phase to embed the
    # EarlGrey framework into the app under test.
    #
    # @param [PBXNativeTarget] target
    # @return [PBXNativeTarget] target
    def add_carthage_search_paths(target)
      target.build_configurations.each do |config|
        settings = config.build_settings
        settings[FRAMEWORK_SEARCH_PATHS] = Array(settings[FRAMEWORK_SEARCH_PATHS])
        unless settings[FRAMEWORK_SEARCH_PATHS].include?(CARTHAGE_BUILD_IOS)
          settings[FRAMEWORK_SEARCH_PATHS] << CARTHAGE_BUILD_IOS
        end

        settings[HEADER_SEARCH_PATHS] = Array(settings[HEADER_SEARCH_PATHS])
        settings[HEADER_SEARCH_PATHS] << CARTHAGE_HEADERS_IOS unless settings[HEADER_SEARCH_PATHS].include?(CARTHAGE_HEADERS_IOS)
      end
      target
    end

    # Add Carthage copy phase
    #
    # @param [PBXNativeTarget] target
    def add_carthage_copy_phase(target)
      shell_script_name = 'Carthage copy-frameworks Run Script'
      target_names = target.shell_script_build_phases.map(&:name)
      unless target_names.include?(shell_script_name)
        shell_script = target.new_shell_script_build_phase shell_script_name
        shell_script.shell_path = '/bin/bash'
        shell_script.shell_script = '/usr/local/bin/carthage copy-frameworks'
        shell_script.input_paths = [CARTHAGE_FRAMEWORK_PATH]
      end
    end

    # Add EarlGrey.framework into the build phase "Link Binary With Libraries"
    #
    # @param [PBXNativeTarget] target
    # @param [PBXFileReference] framework_ref
    #        the framework reference pointing to the EarlGrey.framework
    def add_earlgrey_framework(target, framework_ref)
      linked_frameworks = target.frameworks_build_phase.files.map(&:display_name)
      target.frameworks_build_phase.add_file_reference framework_ref, true unless linked_frameworks.include? EARLGREY_FRAMEWORK
    end

    # Check if the target contains a swift source file
    # @param [PBXNativeTarget] target
    # @return [Boolean]
    # rubocop:disable Style/PredicateName
    def has_swift?(target)
      target.source_build_phase.files_references.any? do |ref|
        SWIFT_FILETYPE == (ref.last_known_file_type || ref.explicit_file_type)
      end
    end
    # rubocop:enable Style/PredicateName

    # Copies EarlGrey.swift and adds it to the project.
    # No op if the target doesn't contain swift.
    #
    # @param [Xcodeproj::Project] project
    # @param [PBXNativeTarget] target
    def copy_swift_files(project, target, swift_version = nil)
      return unless has_swift?(target) || !swift_version.to_s.empty?
      project_test_targets = project.main_group.children
      test_target_group = project_test_targets.find { |g| g.display_name == target.name }

      raise "Test target group not found! #{test_target_group}" unless test_target_group

      swift_version ||= '4.0'
      src_root = File.join(__dir__, 'files')
      dst_root = test_target_group.real_path
      raise "Missing target folder #{dst_root}" unless File.exist? dst_root

      src_swift_name = 'EarlGrey.swift'
      src_swift = File.join(src_root, "Swift-#{swift_version}", src_swift_name)

      unless File.exist? src_swift
        puts_magenta "EarlGrey.swift for version #{swift_version} not found. " \
                     'Falling back to version 4.0.'
        swift_fallback = 'Swift-4.0'
        src_swift = File.join(src_root, swift_fallback, src_swift_name)
        raise "Unable to locate #{swift_fallback} file at path #{src_swift}." unless File.exist?(src_swift)
      end
      dst_swift = File.join(dst_root, src_swift_name)

      FileUtils.copy src_swift, dst_swift

      # Add files to testing target group otherwise Xcode can't read them.
      new_files = [src_swift_name]
      existing_files = test_target_group.children.map(&:display_name)

      new_files.each do |file|
        next if existing_files.include? file
        test_target_group.new_reference(file)
      end

      # Add EarlGrey.swift to sources build phase
      existing_sources = target.source_build_phase.files.map(&:display_name)
      unless existing_sources.include? src_swift_name
        target_files = test_target_group.files
        earlgrey_swift_file_ref = target_files.find { |f| f.display_name == src_swift_name }
        raise 'EarlGrey.swift not found in testing target' unless earlgrey_swift_file_ref
        target.source_build_phase.add_file_reference earlgrey_swift_file_ref, true
      end
    end
  end
end
