Pod::Spec.new do |s|
  s.name     = 'PocketSocket'
  s.version  = '1.0.1'
  s.license  = 'Apache 2.0'
  s.summary  = 'Objective-C websocket client/server library for building things that work in realtime on iOS and OS X.'
  s.description = 'Objective-C websocket client/server library. Conforms fully to RFC6455 websocket protocol, support for websocket compression via the permessage-deflate extension, passes all ~355 Autobahn tests with 100% compliance and comes with a driver level BYO networking API.'
  s.homepage = 'https://github.com/zwopple/PocketSocket'
  s.authors  = { 'Robert Payne' => 'robert@zwopple.com' }
  s.source   = { :git => 'https://github.com/zwopple/PocketSocket.git', :tag => '1.0.1', :submodules => false }
  s.requires_arc = true

  s.ios.deployment_target = '6.0'
  s.osx.deployment_target = '10.8'
  s.tvos.deployment_target = '9.0'

  s.subspec 'Core' do |ss|
    ss.public_header_files = 'PocketSocket/PSWebSocketDriver.h', 'PocketSocket/PSWebSocketTypes.h'
    ss.source_files = 'PocketSocket/PSWebSocketDriver.{h,m}', 'PocketSocket/PSWebSocketTypes.{h,m}', 'PocketSocket/PSWebSocketBuffer.{h,m}', 'PocketSocket/PSWebSocketDeflater.{h,m}', 'PocketSocket/PSWebSocketInflater.{h,m}', 'PocketSocket/PSWebSocketUTF8Decoder.{h,m}', 'PocketSocket/PSWebSocketInternal.h'

    ss.frameworks = 'CFNetwork', 'Foundation', 'Security'
    ss.libraries = 'z', 'system'
  end

  s.subspec 'Client' do |ss|
    ss.dependency 'PocketSocket/Core'
    ss.public_header_files = 'PocketSocket/PSWebSocket.h'
    ss.source_files = 'PocketSocket/PSWebSocket.{h,m}', 'PocketSocket/PSWebSocketNetworkThread.{h,m}'
  end

  s.subspec 'Server' do |ss|
    ss.dependency 'PocketSocket/Client'
    ss.public_header_files = 'PocketSocket/PSWebSocketServer.h'
    ss.source_files = 'PocketSocket/PSWebSocketServer.{h,m}'
  end
end
