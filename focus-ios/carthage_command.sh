# use 0.34.0 because of cross-volume bug with 0.35.0 on BuddyBuild
# https://github.com/Carthage/Carthage/issues/3003
brew uninstall carthage
wget https://github.com/Carthage/Carthage/releases/download/0.34.0/Carthage.pkg
installer -pkg Carthage.pkg -target CurrentUserHomeDirectory
cd /usr/local/bin && ln -s ~/usr/local/bin/carthage .
cd -

xcodevers=`xcodebuild -scheme Focus  -showBuildSettings  | grep -i 'SDK_VERSION =' | sed 's/[ ]*SDK_VERSION = //' | colrm 3`
echo Xcode SDK: "$xcodevers"
if [[ "$xcodevers" != "13" ]]; then
  echo XCode 12 version detected! ••• Please ensure this is correct. ••• 
echo 'EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_simulator__NATIVE_ARCH_64_BIT_x86_64=arm64 arm64e armv7 armv7s armv6 armv8' > /tmp/tmp.xcconfig
echo 'EXCLUDED_ARCHS=$(inherited) $(EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_$(EFFECTIVE_PLATFORM_SUFFIX)__NATIVE_ARCH_64_BIT_$(NATIVE_ARCH_64_BIT))' >> /tmp/tmp.xcconfig
echo 'IPHONEOS_DEPLOYMENT_TARGET=11.4' >> /tmp/tmp.xcconfig
echo 'SWIFT_TREAT_WARNINGS_AS_ERRORS=NO' >> /tmp/tmp.xcconfig
echo 'GCC_TREAT_WARNINGS_AS_ERRORS=NO' >> /tmp/tmp.xcconfig
export XCODE_XCCONFIG_FILE=/tmp/tmp.xcconfig
fi

carthage bootstrap $CARTHAGE_VERBOSE --platform ios --color auto --cache-builds

