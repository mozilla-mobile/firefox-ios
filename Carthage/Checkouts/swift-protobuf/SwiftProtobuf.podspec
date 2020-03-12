Pod::Spec.new do |s|
  s.name = 'SwiftProtobuf'
  s.version = '1.8.0'
  s.license = { :type => 'Apache 2.0', :file => 'LICENSE.txt' }
  s.summary = 'Swift Protobuf code generator plugin and runtime library'
  s.homepage = 'https://github.com/apple/swift-protobuf'
  s.author = 'Apple Inc.'
  s.source = { :git => 'https://github.com/apple/swift-protobuf.git', :tag => s.version }

  s.requires_arc = true
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'
  s.tvos.deployment_target = '9.0'
  s.watchos.deployment_target = '2.0'

  s.cocoapods_version = '>= 1.7.0'

  s.source_files = 'Sources/SwiftProtobuf/**/*.swift'

  s.swift_versions = ['4.0', '4.2', '5.0']
end
