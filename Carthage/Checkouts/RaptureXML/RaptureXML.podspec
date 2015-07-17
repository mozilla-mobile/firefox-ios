Pod::Spec.new do |s|
  s.name          = 'RaptureXML'
  s.version       = '1.0.1'
  s.license       = 'MIT'
  s.summary       = 'A simple, sensible, block-based XML API for iOS and Mac development.'
  s.homepage      = 'https://github.com/ZaBlanc/RaptureXML'
  s.author        = { 'John Blanco' => 'zablanc@gmail.com' }
  s.source        = { :git => 'https://github.com/ZaBlanc/RaptureXML.git', :tag => s.version.to_s }
  s.platform      = :ios
  s.source_files  = 'RaptureXML/*'

  s.libraries     = 'z', 'xml2'
  s.xcconfig      = { 'HEADER_SEARCH_PATHS' => '$(SDKROOT)/usr/include/libxml2' }
  s.requires_arc  = true
end