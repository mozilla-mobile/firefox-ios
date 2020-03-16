#
#  Copyright 2016 Google Inc.
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

require 'earlgrey/cli'
require 'earlgrey/extensions/earlgrey_yaml'
require 'rspec'
require 'tmpdir'
require 'pry' # enables binding.pry
require_relative 'project_diff'

module SpecHelper
  def fixture_path(name)
    # ensure ends with /. for FileUtils.cp_r
    path = File.join(File.expand_path(File.join(__dir__, 'fixtures', name)), '.')
    raise "Path doesn't exist: #{path}" unless File.exist?(path)
    path
  end

  def project_before
    @project_before ||= begin
      fixture_path 'project_before'
    end
  end

  def project_scheme_before
    @project_scheme_before ||= begin
      fixture_path 'project_scheme_before'
    end
  end

  def carthage_after
    @carthage_after ||= begin
      fixture_path 'carthage_after'
    end
  end

  def cocoapods_after
    @cocoapods_after ||= begin
      fixture_path 'cocoapods_after'
    end
  end

  def cocoapods_scheme_after
    @cocoapods_scheme_after ||= begin
      fixture_path 'cocoapods_scheme_after'
    end
  end

  NIL_YAML = "--- \n...\n".freeze

  # project_1 is the temp configured project
  # project_2 is the reference project
  def diff_project(project_init, project_after, command_array)
    raise 'command_array is not an array' unless command_array && command_array.is_a?(Array)
    # dirname for "/fixtures/project_before/." => /fixtures/project_before"
    xcodeproj_2 = File.join(File.dirname(project_after), 'Example.xcodeproj')

    begin
      tmp_dir = File.join(project_init, '../tmpdir')
      FileUtils.cp_r project_init, tmp_dir
      Dir.chdir tmp_dir do
        # carthage modification of xcodeproj is non-deterministic so we can't rely on
        # comparing git diffs because the diffs are always unique... even after
        # normalizing the xcode ids.
        #
        # instead use project-diff which compares a tree hash of the project.

        # must use .start to activate the default value logic in thor.
        EarlGrey::CLI.start command_array

        xcodeproj_1 = File.join(tmp_dir, 'Example.xcodeproj')

        contains_swift_3 = command_array.include? '--swift_version=3.0'
        diff = ProjectDiff.run(xcodeproj_1, xcodeproj_2, contains_swift_3)
        if diff != NIL_YAML
          puts diff
          raise 'difference detected'
        end
      end
    ensure
      FileUtils.rm_rf(Dir.glob(File.join(tmp_dir, '*')).reject { |file| file.end_with?('README') })
    end
  end
end

RSpec.configure do |config|
  config.include SpecHelper
end
