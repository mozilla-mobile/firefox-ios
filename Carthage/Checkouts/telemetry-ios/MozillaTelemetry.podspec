Pod::Spec.new do |s|
  s.name         = "MozillaTelemetry"
  s.version      = "1.1.0"
  s.summary      = "A generic library for sending telemetry pings from iOS applications to Mozilla's telemetry service."
  s.homepage     = "https://github.com/mozilla-mobile/telemetry-ios"
  s.license      = { :type => "Mozilla Public License", :file => "LICENSE" }
  s.author    = ""
  s.source       = { :git => "https://github.com/mozilla-mobile/telemetry-ios.git", :tag => "v#{s.version}" }
  s.source_files  = "Telemetry/**/*.{h,m,swift}"
  s.platform = :ios, '9.0'
end
