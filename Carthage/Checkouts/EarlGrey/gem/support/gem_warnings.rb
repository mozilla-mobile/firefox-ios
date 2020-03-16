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

require 'delegate'

# redefine stderr to include warnings only from the gem's base dir.
# https://gist.github.com/rkh/9130314
$stderr = Class.new(DelegateClass(IO)) do
  BASE_DIR = Regexp.escape(File.dirname(__dir__))

  def write(line)
    return unless line =~ /^#{BASE_DIR}.*:\d+: warning:/
    line.gsub!(BASE_DIR, '.')
    super
  end
end.new($stderr)

require_relative '../lib/earlgrey'
