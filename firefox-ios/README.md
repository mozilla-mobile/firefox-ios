# Firefox for iOS

This is the subdirectory that contains the Firefox for iOS application.

For details on compatible Xcode and Swift versions used to build this project, as well as the minimum iOS version, refer to the root [README](../README.md).

## Getting Involved

For information on how to contribute to this project, including communication channels, coding style, PR naming guidelines and more, visit the [Contribution guidelines](https://github.com/mozilla-mobile/firefox-ios/blob/main/CONTRIBUTING.md).

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

This reduces the total possible number of User Scripts down to four. The compiled output from concatenating and minifying the User Scripts placed in these folders resides in `/Client/Assets` and is named accordingly:

- `AllFramesAtDocumentEnd.js`
- `AllFramesAtDocumentStart.js`
- `MainFrameAtDocumentEnd.js`
- `MainFrameAtDocumentStart.js`

To simplify the build process, these compiled files are checked-in to this repository.

To start a watcher that will compile the User Scripts on save, run the following `npm` command in the root directory of the project:

```shell
npm run dev
```

⚠️ Note: `npm run dev` will build the JS bundles in development mode with source maps, which allows tracking down lines in the source code for debugging.

To create a production build of the User Scripts, run the following `npm` command in the root directory of the project:

```shell
npm run build
```

## Updating License Acknowledgements

In the app, the Settings > Licenses screen credits open source packages we use to build Firefox for iOS.

If you add a new third party package or resource, please update the credits. Follow the instructions in our `license_plist_config.yml` file.
