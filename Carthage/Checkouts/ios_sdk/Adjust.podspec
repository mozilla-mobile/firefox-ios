Pod::Spec.new do |s|
  s.name           = "Adjust"
  s.version        = "4.18.3"
  s.summary        = "This is the iOS SDK of adjust. You can read more about it at http://adjust.com."
  s.homepage       = "https://github.com/adjust/ios_sdk"
  s.license        = { :type => 'MIT', :file => 'MIT-LICENSE' }
  s.author         = { "Christian Wellenbrock" => "welle@adjust.com" }
  s.source         = { :git => "https://github.com/adjust/ios_sdk.git", :tag => "v4.18.3" }
  s.ios.deployment_target = '6.0'
  s.tvos.deployment_target = '9.0'
  s.framework      = 'SystemConfiguration'
  s.ios.weak_framework = 'AdSupport', 'iAd', 'CoreTelephony'
  s.tvos.weak_framework = 'AdSupport'
  s.requires_arc   = true
  s.default_subspec = 'Core'
  s.pod_target_xcconfig = { 'BITCODE_GENERATION_MODE' => 'bitcode' }

  s.subspec 'Core' do |co|
    co.source_files   = 'Adjust/*.{h,m}', 'Adjust/ADJAdditions/*.{h,m}'
  end

  s.subspec 'Sociomantic' do |sm|
    sm.source_files = 'plugin/Sociomantic/*.{h,m}'
    sm.dependency 'Adjust/Core'
  end

  s.subspec 'Criteo' do |cr|
    cr.source_files = 'plugin/Criteo/*.{h,m}'
    cr.dependency 'Adjust/Core'
  end

  s.subspec 'Trademob' do |tm|
    tm.source_files = 'plugin/Trademob/*.{h,m}'
    tm.dependency 'Adjust/Core'
  end

  s.subspec 'WebBridge' do |wb|
    wb.source_files = 'AdjustBridge/*.{h,m}', 'AdjustBridge/WebViewJavascriptBridge/*.{h,m}'
    wb.dependency 'Adjust/Core'
    wb.ios.deployment_target = '6.0'
  end
end
