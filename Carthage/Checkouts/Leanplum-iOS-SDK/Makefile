####################################################################
#
# Rules used to build and release the SDK.
#
####################################################################

updateVersion:
	sed -i '' -e "s/#define LEANPLUM_SDK_VERSION @.*/#define LEANPLUM_SDK_VERSION @\"`cat sdk-version.txt`\"/g" "./Leanplum-SDK/Classes/Internal/LPConstants.h"

tagCommit:
	git add Leanplum-SDK/Classes/Internal/LPConstants.h; git commit -am 'update version'; git tag `cat sdk-version.txt`; git push; git push origin `cat sdk-version.txt`

deploy: updateVersion tagCommit
