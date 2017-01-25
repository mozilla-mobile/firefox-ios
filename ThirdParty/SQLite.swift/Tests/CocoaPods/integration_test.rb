#!/usr/bin/env ruby

require 'minitest/autorun'
require_relative 'test_running_validator'

class IntegrationTest < Minitest::Test

  def test_validate_project
    assert validator.validate, "validation failed: #{validator.failure_reason}"
  end

  private

  def validator
    @validator ||= TestRunningValidator.new(podspec, []).tap do |validator|
        validator.test_files = Dir["#{project_test_dir}/**/*.swift"]
        validator.test_resources = Dir["#{project_test_dir}/fixtures"]
        validator.config.verbose = true
        validator.no_clean = true
        validator.use_frameworks = true
        validator.fail_fast = true
        validator.local = true
        validator.allow_warnings = true
        subspec = ENV['VALIDATOR_SUBSPEC']
        if subspec == 'none'
          validator.no_subspecs = true
        else
          validator.only_subspec = subspec
        end
        if ENV['IOS_SIMULATOR']
          validator.ios_simulator = ENV['IOS_SIMULATOR']
        end
    end
  end

  def podspec
    File.expand_path(File.dirname(__FILE__) + '/../../SQLite.swift.podspec')
  end

  def project_test_dir
    File.expand_path(File.dirname(__FILE__) + '/../SQLiteTests')
  end
end
