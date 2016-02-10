Pod::Spec.new do |s|

  s.name         = "XCGLogger"
  s.version      = "3.2"
  s.summary      = "A debug log module for use in Swift projects."

  s.description  = <<-DESC
                    Allows you to log details to the console (and optionally a file), just like you would have with NSLog() or print(), but with additional information, such as the date, function name, filename and line number.
                    DESC
  s.homepage     = "https://github.com/DaveWoodCom/XCGLogger"

  s.license      = { :type => "MIT", :file => "LICENSE.txt" }
  s.author             = { "Dave Wood" => "cocoapods@cerebralgardens.com" }
  s.social_media_url   = "http://twitter.com/DaveWoodX"
  s.platforms	 = { :ios => "7.0", :watchos => "2.0", :tvos => "9.0" }

  s.source       = { :git => "https://github.com/DaveWoodCom/XCGLogger.git", :tag => "Version_3.2" }
  s.source_files = "XCGLogger/Library/XCGLogger/XCGLogger.swift"

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'
  s.watchos.deployment_target = '2.0'
  s.tvos.deployment_target = '9.0'

  s.framework  = "Foundation"
  s.requires_arc = true

end
