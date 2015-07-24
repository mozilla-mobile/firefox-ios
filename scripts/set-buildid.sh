#!/bin/sh

buildid=`date +"%Y%m%d%H%M%S"`
configpath="${PROJECT_DIR}/${TARGET_NAME}/Configuration"

# Generate the MozBuildID configuration from the template
sed "s/{buildid}/$buildid/g" "$configpath/MozBuildID.xcconfig.template" > "$configpath/MozBuildID.xcconfig" 

