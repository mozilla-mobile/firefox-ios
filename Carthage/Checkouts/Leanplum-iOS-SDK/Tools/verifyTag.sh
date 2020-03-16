#!/bin/bash
tag=`git tag --points-at HEAD`
version=`cat sdk-version.txt`
echo $tag
echo $version
if [ "$tag" == "$version" ]; then
	echo "Tag matches version. Moving forward with deploy"
else
	echo "Tag verification failed"
	exit 1
fi
