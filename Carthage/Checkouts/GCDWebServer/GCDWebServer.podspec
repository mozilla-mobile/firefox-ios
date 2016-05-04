# http://guides.cocoapods.org/syntax/podspec.html
# http://guides.cocoapods.org/making/getting-setup-with-trunk.html
# $ sudo gem update cocoapods
# (optional) $ pod trunk register {email} {name} --description={computer}
# $ pod trunk --verbose push
# DELETE THIS SECTION BEFORE PROCEEDING!

Pod::Spec.new do |s|
  s.name     = 'GCDWebServer'
  s.version  = '3.3.2'
  s.author   =  { 'Pierre-Olivier Latour' => 'info@pol-online.net' }
  s.license  = { :type => 'BSD', :file => 'LICENSE' }
  s.homepage = 'https://github.com/swisspol/GCDWebServer'
  s.summary  = 'Lightweight GCD based HTTP server for OS X & iOS (includes web based uploader & WebDAV server)'
  
  s.source   = { :git => 'https://github.com/swisspol/GCDWebServer.git', :tag => s.version.to_s }
  s.ios.deployment_target = '5.0'
  s.tvos.deployment_target = '9.0'
  s.osx.deployment_target = '10.7'
  s.requires_arc = true
  
  s.default_subspec = 'Core'
  
  s.subspec 'Core' do |cs|
    cs.source_files = 'GCDWebServer/**/*.{h,m}'
    cs.private_header_files = "GCDWebServer/Core/GCDWebServerPrivate.h"
    cs.requires_arc = true
    cs.ios.library = 'z'
    cs.ios.frameworks = 'MobileCoreServices', 'CFNetwork'
    cs.tvos.library = 'z'
    cs.tvos.frameworks = 'MobileCoreServices', 'CFNetwork'
    cs.osx.library = 'z'
    cs.osx.framework = 'SystemConfiguration'
  end
  
  s.subspec "CocoaLumberjack" do |cs|
    cs.dependency 'GCDWebServer/Core'
    cs.dependency 'CocoaLumberjack', '~> 2'
  end
  
  s.subspec 'WebDAV' do |cs|
    cs.default_subspec = 'Core'

    cs.subspec "Core" do |ccs|
      ccs.dependency 'GCDWebServer/Core'
      ccs.source_files = 'GCDWebDAVServer/*.{h,m}'
      ccs.requires_arc = true
      ccs.ios.library = 'xml2'
      ccs.tvos.library = 'xml2'
      ccs.osx.library = 'xml2'
      ccs.compiler_flags = '-I$(SDKROOT)/usr/include/libxml2'
    end

    cs.subspec "CocoaLumberjack" do |cscl|
      cscl.dependency 'GCDWebServer/WebDAV/Core'
      cscl.dependency 'GCDWebServer/CocoaLumberjack'
    end
  end
  
  s.subspec 'WebUploader' do |cs|
    cs.default_subspec = 'Core'

    cs.subspec "Core" do |ccs|
      ccs.dependency 'GCDWebServer/Core'
      ccs.source_files = 'GCDWebUploader/*.{h,m}'
      ccs.requires_arc = true
      ccs.resource = "GCDWebUploader/GCDWebUploader.bundle"
    end

    cs.subspec "CocoaLumberjack" do |cscl|
      cscl.dependency 'GCDWebServer/WebUploader/Core'
      cscl.dependency 'GCDWebServer/CocoaLumberjack'
    end
  end 
end
