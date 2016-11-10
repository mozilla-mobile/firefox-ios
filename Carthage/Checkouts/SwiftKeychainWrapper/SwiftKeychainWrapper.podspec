Pod::Spec.new do |s|
  s.name = 'SwiftKeychainWrapper'
  s.version = '2.1.0'
  s.summary = 'Wrapper for the iOS Keychain written in Swift.'
  s.description = <<-DESC
   A simple wrapper for the iOS Keychain to allow you to use it in a similar fashion to NSUserDefaults. Supports Access Groups. Written in Swift.'
 DESC
  s.module_name = "SwiftKeychainWrapper"
  s.homepage = 'https://github.com/jrendel/SwiftKeychainWrapper'
  s.license = 'MIT'
  s.authors = { 'Jason Rendel' => 'jason@jasonrendel.com' }
  s.ios.deployment_target = '8.0'
  s.source = { :git => 'https://github.com/jrendel/SwiftKeychainWrapper.git', :tag => s.version }
  s.source_files = 'SwiftKeychainWrapper/*.{h,swift}'
end
