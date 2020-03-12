![Leanplum - ](Leanplum.svg)

<p align="center">
    <img src='https://img.shields.io/badge/branch-master-blue.svg'>
    <img src='https://jenkins.leanplum.com/buildStatus/icon?job=apple-sdk-master' alt="Build status">
    &nbsp;&nbsp;&nbsp;&nbsp;
    <img src='https://img.shields.io/badge/branch-develop-red.svg'>
    <img src='https://jenkins.leanplum.com/buildStatus/icon?job=apple-sdk-develop' alt="Build status">
</p>
<p align="center">
<img src="https://img.shields.io/cocoapods/dt/Leanplum-iOS-SDK.svg?maxAge=3600" alt="Downloads" />
<img src="https://img.shields.io/badge/platform-iOS-blue.svg?style=flat" alt="Platform iOS" />
<a href="https://cocoapods.org/pods/Leanplum-iOS-SDK"><img src="https://img.shields.io/cocoapods/v/Leanplum-iOS-SDK.svg?style=flat" alt="CocoaPods compatible" /></a>
<a href="https://github.com/Carthage/Carthage"><img src="https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat" alt="Carthage compatible" /></a>
<a href="https://raw.githubusercontent.com/Leanplum/Leanplum-iOS-SDK/master/LICENSE"><img src="https://img.shields.io/badge/license-apache%202.0-blue.svg?style=flat" alt="License: Apache 2.0" /></a> 
</p>

## Installation & Usage
- Please refer to: https://www.leanplum.com/docs#/setup/ios for how to setup Leanplum SDK in your project.
- To run the example project:
```bash
cd "Example/"
pod install
open "Leanplum-SDK.xcworkspace"
```
## Development Workflow
- We use feature branches that get merged to `master`.
## Build the SDK
To build the sdk run:
```bash
cd "Example/"
pod install
cd -
./build.sh
```
## Contributing
Please follow the guidelines under https://github.com/Leanplum/Leanplum-iOS-SDK/blob/master/CONTRIBUTING.md
## License
See LICENSE file.
## Support
Leanplum does not support custom modifications to the SDK, without an approved pull request (PR). If you wish to include your changes, please fork the repo and send a PR to the develop branch. After the PR has been reviewed and merged into develop it will go into our regular release cycle which includes QA. Once QA has passed the PR will be available in master and your changes are now officialy supported by Leanplum.
