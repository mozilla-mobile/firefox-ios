## libs

This directory builds the required libraries for iOS, Android and desktop platforms.

### Usage

* `./build-all.sh ios` - Build for iOS
* `./build-all.sh android` - Build for Android
* `./build-all.sh desktop` - Build for Desktop

### Build dependencies

* [GYP](https://github.com/mogemimi/pomdog/wiki/How-to-Install-GYP)
* [ninja](https://github.com/ninja-build/ninja/wiki/Pre-built-Ninja-packages)
* [Tcl](https://www.tcl.tk/software/tcltk/)

### Supported architectures

* Android: `TARGET_ARCHS=("x86" "x86_64" "arm64" "arm")`
* iOS: `TARGET_ARCHS=("x86_64" "arm64")`
