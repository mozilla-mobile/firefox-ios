require_relative 'Supporting Files/podspec.rb'

Pod::Spec.new do |spec|
  spec.name = 'SQLiteCipher.swift'
  spec.version = '1.0.0.pre'
  spec.summary = 'The SQLCipher flavor of SQLite.swift.'

  spec.description = <<-DESC
    SQLiteCipher.swift is SQLite.swift built on top of SQLCipher.
  DESC

  apply_shared_config spec, 'SQLiteCipher'

  spec.dependency 'SQLCipher'
  spec.xcconfig = {
    'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) SQLITE_HAS_CODEC=1'
  }
end
