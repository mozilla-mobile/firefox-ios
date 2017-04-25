Leanplum SDK README
===================

This package contains the Leanplum SDK for various platforms, architectures as dynamic and static
framework.

The root of this package contains the recommended dynamic framework builds. Dynamic frameworks
require setting the deployment target to at least '8.0'. Manually installing the .framework file
requires to add the 'Embedded Binaries' and 'Linked Frameworks and Libraries' section in your
target's general tab.

If you require a deployment target of '6.0' or '7.0', please use the static framework in the static/
folder.


## Package Contents

Leanplum.framework                      - The dynamic Leanplum iOS SDK (iOS 8+).
LeanplumLocation.framework              - The dynamic Leanplum Location SDK (iOS 8+).
                                          Include this if your app uses geolocation.
LeanplumLocationAndBeacons.framework    - The dynamic Leanplum Location and Beacons SDK (iOS 8+).
                                          Include this if your app uses iBeacons.
LeanplumTV.framework                    - The dynamic Leanplum tvOS SDK.

LPMessageTemplates.h/.m                 - The open source message templates header file.
                                          Optional: Include if you want to modify the
                                          built-in message templates.

static/                                 - Includes the above but as static frameworks for iOS 6+.
docs/                                   - The generated iOS docs.


## Installation

For step-by-step installation instructions please refer to https://www.leanplum.com/docs#/setup
