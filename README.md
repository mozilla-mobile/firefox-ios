Firefox for iOS [![codebeat badge](https://codebeat.co/badges/67e58b6d-bc89-4f22-ba8f-7668a9c15c5a)](https://codebeat.co/projects/github-com-mozilla-firefox-ios) [![codecov](https://codecov.io/gh/mozilla-mobile/firefox-ios/branch/main/graph/badge.svg)](https://codecov.io/gh/mozilla-mobile/firefox-ios/branch/main)
===============

Download on the [App Store](https://apps.apple.com/app/firefox-web-browser/id989804926).


This branch (main)
-----------

This branch works only with [Xcode 13.4.1](https://developer.apple.com/download/all/?q=xcode), Swift 5.5.2 and supports iOS 13 and above.

*Please note:* Both Intel and M1 macs are supported 🎉 and we use swift package manager.

Please make sure you aim your pull requests in the right direction.

For bug fixes and features for a specific release, use the version branch.

Getting involved
----------------

Want to contribute but don't know where to start? Here is a list of [issues that are contributor friendly](https://github.com/mozilla-mobile/firefox-ios/labels/Contributor%20OK)

Building the code
-----------------

1. Install the latest [Xcode developer tools](https://developer.apple.com/xcode/downloads/) from Apple.
1. Install, [Brew](https://brew.sh), Node, and a Python3 virtualenv for localization scripts:
    ```shell
    brew update
    brew install node
    pip3 install virtualenv
    ```
1. Clone the repository:
    ```shell
    git clone https://github.com/mozilla-mobile/firefox-ios
    ```
1. Install Node.js dependencies, build user scripts and update content blocker:
    ```shell
    cd firefox-ios
    sh ./bootstrap.sh
    ```
1. Open `Client.xcodeproj` in Xcode.
1. Build the `Fennec` scheme in Xcode.

Note: In case you have dependencies issues with SPM, you can try to reset package caches and resolve package version.

Building User Scripts
-----------------

User Scripts (JavaScript injected into the `WKWebView`) are compiled, concatenated, and minified using [webpack](https://webpack.js.org/). User Scripts to be aggregated are placed in the following directories:

```none
/Client
|-- /Frontend
    |-- /UserContent
        |-- /UserScripts
            |-- /AllFrames
            |   |-- /AtDocumentEnd
            |   |-- /AtDocumentStart
            |-- /MainFrame
                |-- /AtDocumentEnd
                |-- /AtDocumentStart
```

This reduces the total possible number of User Scripts down to four. The compiled output from concatenating and minifying the User Scripts placed in these folders resides in `/Client/Assets` and are named accordingly:

* `AllFramesAtDocumentEnd.js`
* `AllFramesAtDocumentStart.js`
* `MainFrameAtDocumentEnd.js`
* `MainFrameAtDocumentStart.js`

To simplify the build process, these compiled files are checked-in to this repository. When adding or editing User Scripts, these files can be re-compiled with `webpack` manually. This requires Node.js to be installed, and all required `npm` packages can be installed by running `npm install` in the project's root directory. User Scripts can be compiled by running the following `npm` command in the root directory of the project:

```shell
npm run build
```

Contributing
-----------------

Want to contribute to this repository? Check out [Contributing Guidelines](https://github.com/mozilla-mobile/firefox-ios/blob/main/CONTRIBUTING.md)

License
-----------------

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at https://mozilla.org/MPL/2.0/
