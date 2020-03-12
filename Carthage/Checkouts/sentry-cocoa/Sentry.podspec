Pod::Spec.new do |s|
  s.name         = "Sentry"
  s.version      = "4.4.3"
  s.summary      = "Sentry client for cocoa"
  s.homepage     = "https://github.com/getsentry/sentry-cocoa"
  s.license      = "mit"
  s.authors      = "Sentry"
  s.source       = { :git => "https://github.com/getsentry/sentry-cocoa.git",
                     :tag => s.version.to_s }

  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.10"
  s.tvos.deployment_target = "9.0"
  s.watchos.deployment_target = "2.0"
  s.module_name  = "Sentry"
  s.requires_arc = true
  s.frameworks = 'Foundation'
  s.libraries = 'z', 'c++'
  s.xcconfig = { 'GCC_ENABLE_CPP_EXCEPTIONS' => 'YES' }

  s.default_subspecs = ['Core']

  s.subspec 'Core' do |sp|
    sp.source_files = "Sources/Sentry/**/*.{h,m}",
                      "Sources/SentryCrash/**/*.{h,m,mm,c,cpp}"
  end
end
