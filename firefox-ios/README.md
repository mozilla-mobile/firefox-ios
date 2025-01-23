# Firefox for iOS

This is the subdirectory that contains the Firefox for iOS application.

## Main branch

Firefox for iOS works with [Xcode 16.1](https://developer.apple.com/download/all/?q=xcode), Swift 5.6 and supports iOS 15.0 and above.

Please make sure you aim your pull requests in the right direction.

For bug fixes and features for a specific release, use the version branch.

## Getting Involved

See readme at the root of the project for [the guidelines](https://github.com/mozilla-mobile/firefox-ios/blob/main/README.md) on how to contribute to this project.

## Building the code

1. Install the latest [Xcode developer tools](https://developer.apple.com/download/all/) from Apple.
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
1. Change directories to the project root:
    ```shell
    cd firefox-ios
    ```
1. From the project root, install Node.js dependencies, build user scripts and update content blocker:
    ```shell
    sh ./bootstrap.sh
    ```
1. Open the `Client.xcodeproj` under the `firefox-ios` folder in Xcode.
1. Make sure to select the `Fennec` [scheme](https://developer.apple.com/documentation/xcode/build-system?changes=_2) in Xcode.
1. Select the destination device you want to build on.
1. Run the app with `Cmd + R` or by pressing the `build and run` button.

⚠️ Important: In case you have dependencies issues with SPM, please try the following:
- Xcode -> File -> Packages -> Reset Package Caches

## Building User Scripts

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

To simplify the build process, these compiled files are checked-in to this repository.

To start a watcher that will compile the User Scripts on save, run the following `npm` command in the root directory of the project:

```shell
npm run dev
```

⚠️ Note: `npm run dev` will build the JS bundles in development mode with source maps, which allows tracking down lines in the source code for debugging.

To create a production build of the User Scripts run the following `npm` command in the root directory of the project:

```shell
npm run build
```
