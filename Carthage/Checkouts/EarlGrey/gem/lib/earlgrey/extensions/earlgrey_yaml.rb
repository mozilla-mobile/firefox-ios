class EarlGreyYaml
  ADD_SWIFT       = 'add_swift'.freeze
  ADD_BUILD_PHASE = 'add_build_phase'.freeze
  ADD_FRAMEWORK   = 'add_framework'.freeze

  def initialize(analyzer, podfile)
    @analyzer         = analyzer
    earlgrey_yml_path = File.join(File.dirname(podfile.defined_in_file.to_s), 'earlgrey_gem.yml')

    @earlgrey_yml = {}
    @earlgrey_yml = YAML.safe_load(File.read(earlgrey_yml_path)) if File.exist?(earlgrey_yml_path)

    validate_targets
    validate_keys
  end

  def validate_targets
    config_targets   = @earlgrey_yml.keys
    existing_targets = @analyzer.targets.map(&:user_targets).flatten.map(&:name)
    missing_targets  = (config_targets - existing_targets).join(', ')

    unless missing_targets.empty?
      error = "ERROR: earlgrey_gem.yml references missing targets: #{missing_targets}\n"
      error += "Valid targets: #{existing_targets}"

      abort error
    end
  end

  def validate_keys
    unknown_keys  = []
    existing_keys = @earlgrey_yml.values.flatten.map(&:keys).flatten
    existing_keys.each do |key|
      unknown_keys << key unless [ADD_SWIFT, ADD_BUILD_PHASE, ADD_FRAMEWORK].include?(key)
    end
    unknown_keys = unknown_keys.join(', ')

    abort "ERROR: earlgrey_gem.yml contains unknown keys: #{unknown_keys}".red unless unknown_keys.empty?
  end

  def lookup_target(native_target)
    target = begin
      @earlgrey_yml.fetch(native_target.name, {})
      # rubocop:disable Style/RescueStandardError
    rescue
      abort("Invalid earlgrey_gem.yaml. Unable to fetch: #{native_target.name}")
    end
    # rubocop:enable Style/RescueStandardError

    tmp = {}
    target.map { |obj| obj.map { |k, v| tmp[k] = v } }

    {
      ADD_SWIFT       => tmp.fetch(ADD_SWIFT, true),
      ADD_BUILD_PHASE => tmp.fetch(ADD_BUILD_PHASE, true),
      ADD_FRAMEWORK   => tmp.fetch(ADD_FRAMEWORK, true)
    }
  end
end
