if [[ "${#}" -ne 1 ]]
then
  echo 'arg missing for updated version number'
  exit 1
fi

# If needed, modify the starting version number locally
# This script is mainly a reference as to what needs to be updated
ls Client/Info.plist Extensions/*/*Info.plist | xargs perl -pi -e "s/0\.0\.1/$1/g" 
