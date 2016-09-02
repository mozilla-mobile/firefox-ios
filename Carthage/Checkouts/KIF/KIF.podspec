Pod::Spec.new do |s|
  s.name                    = "KIF"
  s.version                 = "3.3.2"
  s.summary                 = "Keep It Functional - iOS UI acceptance testing in an XCUnit harness."
  s.homepage                = "https://github.com/kif-framework/KIF/"
  s.license                 = 'Apache 2.0'
  s.authors                 = 'Eric Firestone', 'Jim Puls', 'Brian Nickel'
  s.source                  = { :git => "https://github.com/kif-framework/KIF.git", :tag => "v3.3.2" }
  s.platform                = :ios, '5.1'
  s.frameworks              = 'CoreGraphics', 'IOKit', 'XCTest'
  s.default_subspec         = 'Core'
  s.requires_arc            = true
  s.prefix_header_contents  = '#import <CoreGraphics/CoreGraphics.h>'

  s.subspec 'Core' do |core|
    core.source_files         = 'Classes', 'Additions'
    core.public_header_files  = 'Classes/**/*.h', 'Additions/**/*-KIFAdditions.h', 'Additions/UIView-Debugging.h'
    core.xcconfig             = { 'FRAMEWORK_SEARCH_PATHS' => '$(PLATFORM_DIR)/Developer/Library/Frameworks' }
    core.requires_arc         = true
  end

  s.subspec 'IdentifierTests' do |kiaf|
    kiaf.dependency 'KIF/Core'
    kiaf.source_files        = 'IdentifierTests'
    kiaf.public_header_files = 'IdentifierTests/**/*.h'
    kiaf.requires_arc        = true
  end
end
