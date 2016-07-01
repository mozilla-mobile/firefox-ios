Pod::Spec.new do |s|
  s.name         = "libPhoneNumber-iOS"
  s.version      = "0.8.11"
  s.summary      = "iOS library for parsing, formatting, storing and validating international phone numbers from libphonenumber library."
  s.description  = <<-DESC
libPhoneNumber for iOS
iOS library for parsing, formatting, storing and validating international phone numbers from libphonenumber library.
DESC
  s.homepage     = "https://github.com/iziz/libPhoneNumber-iOS.git"
  s.license      = 'Apache License, Version 2.0 (http://www.apache.org/licenses/LICENSE-2.0)'
  s.authors      = { "iziz" => "zen.isis@gmail.com", "hyukhur" => "hyukhur@gmail.com" }
  s.source       = { :git => "https://github.com/iziz/libPhoneNumber-iOS.git", :tag => s.version }
  s.ios.framework    = 'CoreTelephony'
  s.ios.deployment_target = "6.0"
  s.osx.deployment_target = "10.9"
  s.watchos.deployment_target = "2.0"
  s.requires_arc = true
s.source_files = 'libPhoneNumber/NBPhoneNumberDefines.{h,m}', 'libPhoneNumber/NBPhoneNumber.{h,m}', 'libPhoneNumber/NBNumberFormat.{h,m}', 'libPhoneNumber/NBPhoneNumberDesc.{h,m}', 'libPhoneNumber/NBPhoneMetaData.{h,m}', 'libPhoneNumber/NBPhoneNumberUtil.{h,m}', 'libPhoneNumber/NBMetadataHelper.{h,m}', 'libPhoneNumber/NBAsYouTypeFormatter.{h,m}', 'libPhoneNumber/NBMetadataCore.{h,m}', 'libPhoneNumber/NBMetadataCoreTest.{h,m}', 'libPhoneNumber/NBMetadataCoreMapper.{h,m}', 'libPhoneNumber/NBMetadataCoreTestMapper.{h,m}'
end
