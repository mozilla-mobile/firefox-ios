require_relative 'spec_helper'

module Kernel
  def abort(message = '')
    $stderr.print message
  end
end

describe EarlGreyYaml do
  let(:podfile) do
    podfile = double
    allow(podfile).to receive(:defined_in_file) { File.join(__dir__, '/fixtures/earlgrey_yaml/Podfile') }
    podfile
  end

  let(:valid_target) { 'SampleEarlGreySwiftTests' }

  def mock_analyzer(target_name)
    name = double
    allow(name).to receive(:name) { target_name }

    user_targets = double
    allow(user_targets).to receive(:user_targets) { [name] }

    analyzer = double
    allow(analyzer).to receive(:targets) { [user_targets] }
    analyzer
  end

  it '#validate_targets passes valid targets' do
    analyzer = mock_analyzer(valid_target)
    config   = EarlGreyYaml.new analyzer, podfile
    expect { config.validate_targets }.to output('').to_stderr
  end

  def silence_stderr
    expect($stderr).to receive(:write).at_least(:once) # silence error message
  end

  it '#validate_targets rejects invalid targets' do
    silence_stderr
    config = EarlGreyYaml.new mock_analyzer('InvalidTarget'), podfile
    error  = "ERROR: earlgrey_gem.yml references missing targets: #{valid_target}\n"
    error += 'Valid targets: ["InvalidTarget"]'
    expect { config.validate_targets }.to output(error).to_stderr
  end

  it '#validate_keys passes valid keys' do
    # valid key (using earlgrey_yaml/earlgrey_gem.yml fixture)
    analyzer = mock_analyzer(valid_target)
    config   = EarlGreyYaml.new analyzer, podfile
    config.validate_keys
  end

  it '#validate_keys errors invalid keys' do
    analyzer = mock_analyzer(valid_target)
    config   = EarlGreyYaml.new analyzer, podfile
    fake_yml = { a: [{ b: false }] }
    config.instance_variable_set(:@earlgrey_yml, fake_yml)
    error = 'ERROR: earlgrey_gem.yml contains unknown keys: b'.red
    expect { config.validate_keys }.to output(error).to_stderr
  end

  def mock_target(target_name)
    target = double
    expect(target).to receive(:name) { target_name }
    target
  end

  it '#lookup_target defaults to true on missing' do
    config = EarlGreyYaml.new mock_analyzer(valid_target), podfile

    target = mock_target('does not exist')
    expect(config.lookup_target(target))
      .to eq(
        EarlGreyYaml::ADD_BUILD_PHASE => true,
        EarlGreyYaml::ADD_FRAMEWORK   => true,
        EarlGreyYaml::ADD_SWIFT       => true
      )
  end

  it '#lookup_target reads config for target' do
    config = EarlGreyYaml.new mock_analyzer(valid_target), podfile

    target = mock_target(valid_target)
    expect(config.lookup_target(target))
      .to eq(
        EarlGreyYaml::ADD_BUILD_PHASE => false,
        EarlGreyYaml::ADD_FRAMEWORK   => false,
        EarlGreyYaml::ADD_SWIFT       => false
      )
  end
end
