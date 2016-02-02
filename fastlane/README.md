fastlane documentation
================
# Installation
```
sudo gem install fastlane
```
# Available Actions
## iOS
### ios aurora
```
fastlane ios aurora
```
Builds an Aurora build. Takes the following arguments: 
   :build            the build number for this build. Defaults to current build number 
   :version          the version number for this build. Defaults to current version number 
   :branch           the branch to build (will create if doesn't already exist. A new branch with a predictable username will be     created if this is not provided) 
   :base_branch      the branch with off of which the build should be based (current branch if empty) 
   :build_name       the name of the resultant build. Defaults to firefox-ios-aurora-<:version>-<:build>-<timestamp> 
   :username         the Apple ID to use to log into the developer portal for SIGH 
   :localise         if true, the branch will be localised. If absent or false no localisation will occur 
   :upload           if true, the build will be uploaded to the enterprise server (see the upload lane for further paramters to pass     for uploading)
### ios l10n
```
fastlane ios l10n
```
Builds an l10n build. Takes the following arguments: 
   :build            the build number for this build. Defaults to current build number 
   :version          the version number for this build. Defaults to current version number 
   :branch           the branch to build (will create if doesn't already exist. A new branch with a predictable username will     be created if this is not provided) 
   :base_branch      the branch with off of which the build should be based (current branch if empty) 
   :build_name       the name of the resultant build. Defaults to firefox-ios-l10n-<:version>-<:build>-<timestamp> 
   :username         the Apple ID to use to log into the developer portal for SIGH 
   :localise         if true, the branch will be localised. If absent or false no localisation will occur 
   :upload           if true, the build will be uploaded to the enterprise server (see the upload lane for further paramters to pass     for uploading)
### ios beta
```
fastlane ios beta
```
Builds an beta build for the Firefox channel. Takes the following arguments: 
   :build                the build number for this build. Defaults to current build number 
   :version              the version number for this build. Defaults to current version number 
   :branch               the branch to build (will create if doesn't already exist. A new branch with a predictable username will     be created if this is not provided) 
   :base_branch          the branch with off of which the build should be based (current branch if empty) 
   :build_name           the name of the resultant build. Defaults to firefox-ios-l10n-<:version>-<:build>-<timestamp> 
   :username             the Apple ID to use to log into the developer portal for SIGH 
   :localise             if true, the branch will be localised. If absent or false no localisation will occur 
   :changelog            the path to the changelog for the beta build 
   :adjust_environment   the environment to setup Adjust for 
   :adjust_app_token     the app token for Adjust
### ios fennec
```
fastlane ios fennec
```
Builds an beta build for the Fennec channel. Takes the following arguments: 
   :build            the build number for this build. Defaults to current build number 
   :version          the version number for this build. Defaults to current version number 
   :branch           the branch to build (will create if doesn't already exist. A new branch with a predictable username will     be created if this is not provided) 
   :base_branch      the branch with off of which the build should be based (current branch if empty) 
   :build_name       the name of the resultant build. Defaults to firefox-ios-l10n-<:version>-<:build>-<timestamp> 
   :username         the Apple ID to use to log into the developer portal for SIGH 
   :localise         if true, the branch will be localised. If absent or false no localisation will occur 
   :changelog        the path to the changelog for the beta build
### ios upload
```
fastlane ios upload
```
Uploads an ipa. Takes the following arguments: 
   :build            the build number for this build 
   :version          the version number for this build 
   :release_notes    the location of the release notes for this build. Defaults to `../release_notes.txt` 
   :plist            the location of the plist template. 
   :html             the location of the html template 
   :build_location   the location of the build to upload. Defaults to `builds` 
   :build_name       the name of the build to upload 
   :upload_host      the name of the host to upload to. Defaults to people.mozilla.org 
   :upload.location  the location on the :host to upload the build artifacts to. Defaults to /home/iosbuilds
### ios marketing
```
fastlane ios marketing
```
Takes marketing snapshots using current branch
### ios snapshotL10n
```
fastlane ios snapshotL10n
```
Takes localization snapshots   :devices - a list of devices to take snapshots on   :languages - a list of languages to take snapshots of   :output_directory - the directory to output the snapshots to

----

This README.md is auto-generated and will be re-generated every time to run [fastlane](https://fastlane.tools)
More information about fastlane can be found on [https://fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [GitHub](https://github.com/fastlane/fastlane)