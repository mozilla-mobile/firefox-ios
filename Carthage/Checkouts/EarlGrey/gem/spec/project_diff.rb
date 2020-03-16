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

require 'yaml'
require 'digest/sha1'

# Define a custom project diff to avoid path names from showing up in the report.
# The tests use a temporary directory and the path to that will always be different
# from the path to the fixtures dir.
class ProjectDiff
  class << self
    def tree(path)
      raise "Path doesn't exist: #{path}" unless File.exist? path
      Xcodeproj::Project.open(path).to_tree_hash.dup
    end

    def sha1(file_name)
      file_path = File.expand_path(File.join(file_name))
      Digest::SHA1.hexdigest(File.read(file_path))
    end

    def validate_swift_version(version)
      raise 'Invalid version. Expected 3.0 or 4.0' unless %w[3.0 4.0].include?(version)
    end

    def earlgrey_path(version)
      validate_swift_version version
      File.expand_path(File.join(__dir__, '..', 'lib', 'earlgrey', 'files',
                                 "Swift-#{version}", 'EarlGrey.swift'))
    end

    def swift_mismatch_error(version)
      validate_swift_version(version)
      <<-FF
          The wrong Swift #{version} file was downloaded. Please File a Bug against the EarlGrey
          gem at https://github.com/google/EarlGrey/issues.
      FF
    end

    def expected_hash(version)
      case version
      when '3.0'
        @swift_3_0_sha1 ||= sha1(earlgrey_path('3.0'))
      when '4.0'
        @swift_4_0_sha1 ||= sha1(earlgrey_path('4.0'))
      else
        raise 'Invalid version'
      end
    end

    # Based on code from:
    # https://github.com/CocoaPods/Xcodeproj/blob/480e2f99e5e9315b8032854a9530aa500761e138/lib/xcodeproj/command/project_diff.rb
    def run(path_1, path_2, has_swift_3)
      actual_swift_file = File.join(path_1, '..', 'ExampleTests/EarlGrey.swift')
      swift_version = has_swift_3 ? '3.0' : '4.0'

      hash_match = expected_hash(swift_version) == sha1(actual_swift_file)
      raise swift_mismatch_error(swift_version) unless hash_match

      Xcodeproj::Differ.project_diff(tree(path_1), tree(path_2)).to_yaml
    end
  end
end
