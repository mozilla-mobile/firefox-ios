Pod::Spec.new do |s|
  s.name         = "Fuzi"
  s.version      = "3.1.1"
  s.license      = "MIT"
  s.summary      = "A fast & lightweight XML & HTML parser in Swift with XPath & CSS support"
  s.homepage     = "https://github.com/cezheng/Fuzi"
  s.social_media_url   = "https://twitter.com/AdamoCheng"
  s.author             = { "Ce Zheng" => "cezheng.cs@gmail.com" }
  s.source       = { :git => "https://github.com/cezheng/Fuzi.git", :tag => s.version }

  # cocoadocs.org might not be working
  # s.documentation_url = "http://cezheng.github.io/Fuzi"
  
  s.ios.deployment_target = "8.0"
  s.osx.deployment_target = "10.9"
  s.watchos.deployment_target = "2.0"
  s.tvos.deployment_target = "9.0"

  s.source_files  = "Sources/*.swift"

  s.requires_arc = true
  s.library = "xml2"
  s.xcconfig = { 'HEADER_SEARCH_PATHS' => '$(SDKROOT)/usr/include/libxml2' }
end
