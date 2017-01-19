Pod::Spec.new do |spec|
  spec.name = 'JSONSchema'
  spec.version = '0.3.0'
  spec.summary = 'JSON Schema validator in Swift.'
  spec.homepage = 'https://github.com/kylef/JSONSchema.swift'
  spec.license = { :type => 'BSD', :file => 'LICENSE' }
  spec.author = { 'Kyle Fuller' => 'kyle@fuller.li' }
  spec.social_media_url = 'http://twitter.com/kylefuller'
  spec.source = { :git => 'https://github.com/kylef/JSONSchema.swift.git', :tag => "#{spec.version}" }
  spec.ios.deployment_target = '8.0'
  spec.osx.deployment_target = '10.9'
  spec.requires_arc = true
  spec.source_files = 'Sources/JSONSchema.{h,swift}', 'Sources/Validators.swift'
end

