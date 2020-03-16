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

require_relative '../configure_earlgrey'
require_relative 'aggregate_target_extensions'
require_relative 'earlgrey_yaml'

module EarlGrey
  module AnalyzerExtension
    def analyze(*_)
      result = super
      earlgrey_yaml = EarlGreyYaml.new(result, podfile)
      eg_targets = result.targets.select(&:is_earlgrey?).each do |target|
        target.user_targets.each do |native_target|
          config = earlgrey_yaml.lookup_target native_target

          if config[EarlGreyYaml::ADD_SWIFT]
            EarlGrey.copy_swift_files(target.user_project, native_target,
                                      target.target_definition.swift_version)
          end

          framework_ref = EarlGrey.add_earlgrey_product target.user_project, false
          EarlGrey.add_earlgrey_copy_files_script native_target, framework_ref if config[EarlGreyYaml::ADD_BUILD_PHASE]
          EarlGrey.add_earlgrey_framework native_target, framework_ref if config[EarlGreyYaml::ADD_FRAMEWORK]
        end
      end

      schemes = eg_targets.map(&:schemes_for_native_targets).flatten(1).uniq do |name, _|
        name
      end
      schemes.each do |name, scheme|
        EarlGrey.add_environment_variables_to_test_scheme(name, scheme)
      end
      result
    end
  end
end

module Pod
  class Installer
    class Analyzer
      prepend EarlGrey::AnalyzerExtension
    end
  end
end
