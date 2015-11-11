# How to get your browser DB off the device

* Launch Firefox.
* Open Settings.
* Scroll down to "Version" and tap it several times.
* Scroll down and hit "Debug: copy databases to app container".
* Connect your device via USB.
* Open Xcode.
* Window > Devices. Choose your device.
* Find "Firefox" on the right side.
* Click the gear icon, and choose "Download Container…". Save it somewhere.
* After some time, Finder will open focused on an .xcappdata file.
* Right-click, "Show Package Contents".
* Navigate to `AppData/Documents`. Zip up `browser.*`.
