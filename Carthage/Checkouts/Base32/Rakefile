require 'xcjobs'

def destinations
  [ 'name=iPad 2',
    'name=iPad Air',
    'name=iPhone 4s',
    'name=iPhone 5',
    'name=iPhone 5s',
    'name=iPhone 6',
    'name=iPhone 6 Plus'
  ]
end

namespace :test do
  xcode_test :ios do |t|
    t.project = 'Base32'
    t.scheme = 'Base32-iOS'
    t.sdk = 'iphonesimulator'
    t.configuration = 'Release'
    destinations.each do |destination|
      t.add_destination(destination)
    end
    t.formatter = 'xcpretty -c'
  end

  xcode_test :osx do |t|
    t.project = 'Base32'
    t.scheme = 'Base32-Mac'
    t.sdk = 'macosx'
    t.configuration = 'Release'
    t.formatter = 'xcpretty -c'
  end

  xcode_test :SecEncodeTransformTests do |t|
    t.project = 'Base32'
    t.scheme = 'SecEncodeTransformTests'
    t.sdk = 'macosx'
    t.configuration = 'Release'
    t.formatter = 'xcpretty -c'
  end
end

# If this environment variable is missing, we must not be running on Travis.
if ENV["KEY_PASSWORD"]
  XCJobs::Certificate.new do |t|
    t.add_certificate('./certificates/AppleWWDRCA.cer')
    t.add_certificate('./certificates/development.p12', ENV["KEY_PASSWORD"])
  end
else
  namespace :certificates do
    task :install do
      puts "skip certificates:install because KEY_PASSWORD does not exists."
    end
  end
end
