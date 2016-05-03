Pod::Spec.new do |spec|

  spec.name 				= "1PasswordExtension"
  spec.header_dir 			= "OnePasswordExtension"
  spec.header_mappings_dir 	= "OnePasswordExtension"
  spec.version 				= "1.7"
  spec.summary 				= "With just a few lines of code, your app can add 1Password support."
  spec.description 			= <<-DESC
 							With just a few lines of code, your app can add 1Password support, enabling your users to:

 							- Access their 1Password Logins to automatically fill your login page.
 							- Use the Strong Password Generator to create unique passwords during registration, and save the new Login within 1Password.
 							- Quickly fill 1Password Logins directly into web views.

 							Empowering your users to use strong, unique passwords has never been easier.
 							DESC

  spec.homepage 			= "https://github.com/AgileBits/onepassword-app-extension"
  spec.license 				= { :type => 'MIT', :file => 'LICENSE.txt' }
  spec.authors 				= [ "Dave Teare", "Michael Fey", "Rad Azzouz", "Roustem Karimov" ]
  spec.social_media_url 	= "https://twitter.com/1Password"

  spec.source 				= { :git => "https://github.com/AgileBits/onepassword-app-extension.git", :tag => spec.version }
  spec.platform 			= :ios, 7.0
  spec.source_files 		= "*.{h,m}"
  spec.frameworks 			= [ 'Foundation', 'MobileCoreServices', 'UIKit' ]
  spec.weak_framework 		= "WebKit"
  spec.exclude_files 		= "Demos"
  spec.resource_bundles 	= { 'OnePasswordExtensionResources' => ['1Password.xcassets/*.imageset/*.png', '1Password.xcassets'] }
  spec.requires_arc 		= true
end
