require_relative 'Supporting Files/podspec.rb'

Pod::Spec.new do |spec|
  spec.name = 'SQLite.swift'
  spec.summary = 'A type-safe, Swift-language layer over SQLite3.'

  spec.description = <<-DESC
    SQLite.swift provides compile-time confidence in SQL statement syntax and
    intent.
  DESC

  apply_shared_config spec, 'SQLite'

  spec.exclude_files = 'Source/Cipher/Cipher.swift'
  spec.library = 'sqlite3'
end
