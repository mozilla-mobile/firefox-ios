# the first argument is the current version, and the second is the new version
if [[ "${#}" -ne 2 ]]
then
  echo 'arg missing for updated version number'
  exit 1
fi

# If needed, modify the starting version number locally
# This script is mainly a reference as to what needs to be updated
perl -pi -e "s/$1/$2/g" firefox-ios/Client/Info.plist
perl -pi -e "s/$1/$2/g" firefox-ios/CredentialProvider/Info.plist
perl -pi -e "s/$1/$2/g" firefox-ios/Extensions/*/*Info.plist
perl -pi -e "s/$1/$2/g" firefox-ios/WidgetKit/Info.plist
perl -pi -e "s/$1/$2/g" bitrise.yml
