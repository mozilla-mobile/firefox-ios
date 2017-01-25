Pod::Spec.new do |s|
  s.name             = "SQLite.swift"
  s.version          = "0.11.2"
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
  s.ios.deployment_target = "8.0"
  s.tvos.deployment_target = "9.0"
  s.osx.deployment_target = "10.9"
  s.watchos.deployment_target = "2.0"
  s.default_subspec  = 'standard'
  s.pod_target_xcconfig = {
    'SWIFT_VERSION' => '3.0',
  }

  s.subspec 'standard' do |ss|
    ss.source_files = 'Sources/{SQLite,SQLiteObjc}/**/*.{c,h,m,swift}'
    ss.exclude_files = 'Sources/**/Cipher.swift'
    ss.private_header_files = 'Sources/SQLiteObjc/*.h'

    ss.library = 'sqlite3'
    ss.preserve_paths = 'CocoaPods/**/*'
    ss.pod_target_xcconfig = {
      'SWIFT_INCLUDE_PATHS[sdk=macosx*]'             => '$(SRCROOT)/SQLite.swift/CocoaPods/macosx',
      'SWIFT_INCLUDE_PATHS[sdk=macosx10.11]'         => '$(SRCROOT)/SQLite.swift/CocoaPods/macosx-10.11',
      'SWIFT_INCLUDE_PATHS[sdk=macosx10.12]'         => '$(SRCROOT)/SQLite.swift/CocoaPods/macosx-10.12',
      'SWIFT_INCLUDE_PATHS[sdk=iphoneos*]'           => '$(SRCROOT)/SQLite.swift/CocoaPods/iphoneos',
      'SWIFT_INCLUDE_PATHS[sdk=iphoneos10.0]'        => '$(SRCROOT)/SQLite.swift/CocoaPods/iphoneos-10.0',
      'SWIFT_INCLUDE_PATHS[sdk=iphonesimulator*]'    => '$(SRCROOT)/SQLite.swift/CocoaPods/iphonesimulator',
      'SWIFT_INCLUDE_PATHS[sdk=iphonesimulator10.0]' => '$(SRCROOT)/SQLite.swift/CocoaPods/iphonesimulator-10.0',
      'SWIFT_INCLUDE_PATHS[sdk=appletvos*]'          => '$(SRCROOT)/SQLite.swift/CocoaPods/appletvos',
      'SWIFT_INCLUDE_PATHS[sdk=appletvsimulator*]'   => '$(SRCROOT)/SQLite.swift/CocoaPods/appletvsimulator',
      'SWIFT_INCLUDE_PATHS[sdk=watchos*]'            => '$(SRCROOT)/SQLite.swift/CocoaPods/watchos',
      'SWIFT_INCLUDE_PATHS[sdk=watchsimulator*]'     => '$(SRCROOT)/SQLite.swift/CocoaPods/watchsimulator'
    }
  end

  s.subspec 'standalone' do |ss|
    ss.source_files = 'Sources/{SQLite,SQLiteObjc}/**/*.{c,h,m,swift}'
    ss.exclude_files = 'Sources/**/Cipher.swift'
    ss.private_header_files = 'Sources/SQLiteObjc/*.h'
    ss.xcconfig = {
      'OTHER_SWIFT_FLAGS' => '$(inherited) -DSQLITE_SWIFT_STANDALONE'
    }

    ss.dependency 'sqlite3', '>= 3.14.0'
  end

  s.subspec 'SQLCipher' do |ss|
    ss.source_files = 'Sources/{SQLite,SQLiteObjc}/**/*.{c,h,m,swift}'
    ss.private_header_files = 'Sources/SQLiteObjc/*.h'
    ss.xcconfig = {
      'OTHER_SWIFT_FLAGS' => '$(inherited) -DSQLITE_SWIFT_SQLCIPHER',
      'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) SQLITE_HAS_CODEC=1'
    }

    ss.dependency 'SQLCipher', '>= 3.4.0'
  end
end
