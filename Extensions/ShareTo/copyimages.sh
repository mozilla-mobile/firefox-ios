dest="Extensions/ShareTo/Images.xcassets/copied_by_build_script"
mkdir -p $dest

rsync -a ./Client/Frontend/Home/Home.xcassets/emptySync.imageset $dest

for file in \
"deviceTypeMobile.imageset" \
"deviceTypeDesktop.imageset" \
"quickSearch.imageset" \
"faviconFox.imageset" \
"New Tab - Reader/addToReadingList.imageset" \
; do
  rsync -a "Client/Assets/Images.xcassets/$file" $dest
done

for file in \
"menu-Disclosure.imageset" \
"menu-Send-to-Device.imageset" \
"menu-Show-Tabs.imageset" \
"menu-Bookmark.imageset" \
; do
  rsync -a "Client/Frontend/Menu/Menu.xcassets/$file" $dest
done
