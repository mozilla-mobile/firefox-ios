/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef XCUITests_Bridging_Header_h
#define XCUITests_Bridging_Header_h

#import "XCTest/XCUIApplication.h"
#import "XCTest/XCUIElement.h"
@interface XCUIApplication (Private)
- (id)initPrivateWithPath:(NSString *)path bundleID:(NSString *)bundleID;
@end

#endif
