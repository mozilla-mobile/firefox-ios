Firefox for iOS [![codebeat badge](https://codebeat.co/badges/67e58b6d-bc89-4f22-ba8f-7668a9c15c5a)](https://codebeat.co/projects/github-com-mozilla-firefox-ios) [![BuddyBuild](https://dashboard.buddybuild.com/api/statusImage?appID=57bf25c0f096bc01001e21e0&branch=master&build=latest)](https://dashboard.buddybuild.com/apps/57bf25c0f096bc01001e21e0/build/latest) [![codecov](https://codecov.io/gh/mozilla-mobile/firefox-ios/branch/master/graph/badge.svg)](https://codecov.io/gh/mozilla-mobile/firefox-ios/branch/master)
===============

Download on the [App Store](https://itunes.apple.com/app/firefox-web-browser/id989804926).

This branch (master)
-----------

This branch only works with [Xcode 11.4](https://apps.apple.com/app/xcode/id497799835), Swift 5.2 and supports iOS 12.0 and above.

Please make sure you aim your pull requests in the right direction.

For bug fixes and features for a specific release use the version branch.

Getting involved
----------------

Want to contribute but don't know where to start? Here is a list of [issues that are contributor friendly](https://github.com/mozilla-mobile/firefox-ios/issues?q=is%3Aissue+is%3Aopen+label%3A%22Contributor+OK+%F0%9F%A4%9D%22)

Building the code
-----------------

1. Install the latest [Xcode developer tools](https://developer.apple.com/xcode/downloads/) from Apple.
1. Install Carthage and Node
    ```shell
    brew update
    brew install carthage
    brew install node
    ```
1. Clone the repository:
    ```shell
    git clone https://github.com/mozilla-mobile/firefox-ios
    ```
1. Pull in the project dependencies:
    ```shell
    cd firefox-ios
    sh ./bootstrap.sh
    ```
1. Open `Client.xcodeproj` in Xcode.
1. Build the `Fennec` scheme in Xcode.

## Building User Scripts

User Scripts (JavaScript injected into the `WKWebView`) are compiled, concatenated and minified using [webpack](https://webpack.js.org/). User Scripts to be aggregated are placed in the following directories:

```
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

To simplify the build process, these compiled files are checked-in to this repository. When adding or editing User Scripts, these files can be re-compiled with `webpack` manually. This requires Node.js to be installed and all required `npm` packages can be installed by running `npm install` in the root directory of the project. User Scripts can be compiled by running the following `npm` command in the root directory of the project:

```
npm run build
```

## Contributing

Want to contribute to this repository? Check out [Contributing Guidelines](https://github.com/mozilla-mobile/firefox-ios/blob/master/CONTRIBUTING.md)
