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

require_relative 'lib/earlgrey/version'

Gem::Specification.new do |s|
  s.required_ruby_version = '>= 2.1'

  s.name          = 'earlgrey'
  s.version       = EarlGrey::VERSION
  s.license       = 'Apache-2.0'
  s.summary       = 'EarlGrey installer gem'
  s.description   = 'Command line tool for installing EarlGrey into an iOS Unit Testing target'
  s.authors       = %w[khandpur tirodkar bootstraponline wuhao5]
  s.homepage      = 'https://github.com/google/EarlGrey'
  s.require_paths = ['lib']

  s.add_runtime_dependency 'colored',   '>= 1.2'
  s.add_runtime_dependency 'thor',      '>= 0.19.1'
  s.add_runtime_dependency 'xcodeproj', '>= 1.3.0'

  s.add_development_dependency 'pry',         '~> 0.10.3'
  s.add_development_dependency 'rake',        '~> 11.1'
  s.add_development_dependency 'rspec',       '>= 3.4.0'
  s.add_development_dependency 'rubocop',     '>= 0.39.0'

  # everything that starts with bin/ or lib/
  s.files         = `git ls-files -z`.split("\x0").grep(%r{^(bin|lib)/})
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
end
