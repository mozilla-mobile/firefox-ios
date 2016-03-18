#
# `pod lib lint SQLite.swift.podspec' fails - see
#    https://github.com/CocoaPods/CocoaPods/issues/4607
#

Pod::Spec.new do |s|
  s.name             = "SQLite.swift"
  s.version          = "0.9.0"
  s.summary          = "A type-safe, Swift-language layer over SQLite3 for iOS and OS X."

  s.description      = <<-DESC
    SQLite.swift provides compile-time confidence in SQL statement syntax and
    intent.
                       DESC

  s.homepage         = "https://github.com/stephencelis/SQLite.swift"
  s.license          = 'MIT'
  s.author           = { "Stephen Celis" => "stephen@stephencelis.com" }
  s.source           = { :git => "https://github.com/stephencelis/SQLite.swift.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/stephencelis'

  s.module_name      = 'SQLite'
  s.module_map       = 'module.modulemap'

  s.source_files = 'SQLite/**/*'

  # make the sqlite3 C library behave like a module
  s.libraries        = 'sqlite3'
  s.xcconfig         = { 'SWIFT_INCLUDE_PATHS' => '${PODS_ROOT}/SQLite.swift/SQLite3' }
  s.preserve_path    = 'SQLite3/*'

end
