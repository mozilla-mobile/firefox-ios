#
# Create builds directory if not already present
#
if [ ! -d builds ]; then
	mkdir builds || exit 1
fi

#
# Create provisioning profile directory if not already present
#
if [ ! -d provisioning-profiles ]; then
	mkdir provisioning-profiles || exit 1
fi

#
# if we are doing a release or l10n build then make a folder for storing screenshots
#
if [ ! -d screenshots ]; then
	mkdir screenshots || exit 1
fi