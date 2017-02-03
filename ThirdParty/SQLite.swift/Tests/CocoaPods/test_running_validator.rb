require 'cocoapods'
require 'cocoapods/validator'
require 'fileutils'

class TestRunningValidator < Pod::Validator
  APP_TARGET = 'App'
  TEST_TARGET = 'Tests'

  attr_accessor :test_files
  attr_accessor :test_resources
  attr_accessor :ios_simulator
  attr_accessor :tvos_simulator
  attr_accessor :watchos_simulator

  def initialize(spec_or_path, source_urls)
    super(spec_or_path, source_urls)
    self.test_files = []
    self.test_resources = []
    self.ios_simulator = :oldest
    self.tvos_simulator = :oldest
    self.watchos_simulator = :oldest
  end

  def create_app_project
    super
    project = Xcodeproj::Project.open(validation_dir + "#{APP_TARGET}.xcodeproj")
    create_test_target(project)
    project.save
  end

  def add_app_project_import
    super
    project = Xcodeproj::Project.open(validation_dir + 'App.xcodeproj')
    group = project.new_group(TEST_TARGET)
    test_target = project.targets.last
    test_target.add_resources(test_resources.map { |resource| group.new_file(resource) })
    test_target.add_file_references(test_files.map { |file| group.new_file(file) })
    add_swift_version(test_target)
    project.save
  end

  def install_pod
    super
    if local?
      FileUtils.ln_s file.dirname, validation_dir + "Pods/#{spec.name}"
    end
  end

  def podfile_from_spec(*args)
    super(*args).tap do |pod_file|
      add_test_target(pod_file)
    end
  end

  def build_pod
    super
    Pod::UI.message "\Testing with xcodebuild.\n".yellow do
      run_tests
    end
  end

  private
  def create_test_target(project)
    test_target = project.new_target(:unit_test_bundle, TEST_TARGET, consumer.platform_name, deployment_target)
    create_test_scheme(project, test_target)
  end

  def create_test_scheme(project, test_target)
    project.recreate_user_schemes
    test_scheme = Xcodeproj::XCScheme.new(test_scheme_path(project))
    test_scheme.add_test_target(test_target)
    test_scheme.save!
  end

  def test_scheme_path(project)
    Xcodeproj::XCScheme.user_data_dir(project.path) + "#{TEST_TARGET}.xcscheme"
  end

  def add_test_target(pod_file)
    app_target = pod_file.target_definitions[APP_TARGET]
    Pod::Podfile::TargetDefinition.new(TEST_TARGET, app_target)
  end

  def run_tests
    command = [
      'clean', 'build', 'build-for-testing', 'test-without-building',
      '-workspace', File.join(validation_dir, "#{APP_TARGET}.xcworkspace"),
      '-scheme', TEST_TARGET,
      '-configuration', 'Debug'
    ]
    case consumer.platform_name
    when :ios
      command += %w(CODE_SIGN_IDENTITY=- -sdk iphonesimulator)
      command += Fourflusher::SimControl.new.destination(ios_simulator, 'iOS', deployment_target)
    when :osx
      command += %w(LD_RUNPATH_SEARCH_PATHS=@loader_path/../Frameworks)
    when :tvos
      command += %w(CODE_SIGN_IDENTITY=- -sdk appletvsimulator)
      command += Fourflusher::SimControl.new.destination(tvos_simulator, 'tvOS', deployment_target)
    when :watchos
      # there's no XCTest on watchOS (https://openradar.appspot.com/21760513)
      return
    else
      return
    end

    output, status = _xcodebuild(command)

    unless status.success?
      message = 'Returned an unsuccessful exit code.'
      if config.verbose?
        message += "\nXcode output: \n#{output}\n"
      else
        message += ' You can use `--verbose` for more information.'
      end
      error('xcodebuild', message)
    end
    output
  end
end
