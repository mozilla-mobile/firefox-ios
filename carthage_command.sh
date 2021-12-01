xcodesdk=`xcodebuild -scheme Firefox  -showBuildSettings  | grep -i 'SDK_VERSION =' | sed 's/[ ]*SDK_VERSION = //' | colrm 3`
echo Xcode SDK: $(($xcodesdk+0))

# Make sure we're on Xcode greater than 12
if [[ 13 -gt $(($xcodesdk+0)) ]]; then
  echo Xcode 12 version \(SDK 13\) or more should be used! 
  exit 0
fi

echo 'EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_simulator__NATIVE_ARCH_64_BIT_x86_64=arm64 arm64e armv7 armv7s armv6 armv8' > /tmp/tmp.xcconfig
echo 'EXCLUDED_ARCHS=$(inherited) $(EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_$(EFFECTIVE_PLATFORM_SUFFIX)__NATIVE_ARCH_64_BIT_$(NATIVE_ARCH_64_BIT))' >> /tmp/tmp.xcconfig
echo 'IPHONEOS_DEPLOYMENT_TARGET=11.4' >> /tmp/tmp.xcconfig
echo 'SWIFT_TREAT_WARNINGS_AS_ERRORS=NO' >> /tmp/tmp.xcconfig
echo 'GCC_TREAT_WARNINGS_AS_ERRORS=NO' >> /tmp/tmp.xcconfig
export XCODE_XCCONFIG_FILE=/tmp/tmp.xcconfig

carthage bootstrap $CARTHAGE_VERBOSE --platform ios --color auto --cache-builds
exit 1
