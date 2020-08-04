/*
 * Building OpenSSL for the different architectures of all iOS and tvOS devices requires different settings.
 * In order to be able to use assembly code on all devices, the choice was made to keep optimal settings for all
 * devices and use this intermediate header file to use the proper opensslconf.h file for each architecture.

 * See also https://github.com/x2on/OpenSSL-for-iPhone/issues/126 and referenced pull requests
 */

#include <TargetConditionals.h>

#if TARGET_OS_IOS && TARGET_OS_SIMULATOR
# include <openssl/opensslconf_ios_x86_64.h>
#elif
# include <openssl/opensslconf_tvos_arm64.h>
#else
# error Unable to determine target or target not included in OpenSSL build
#endif
