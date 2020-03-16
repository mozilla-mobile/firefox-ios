//
// Copyright 2016 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import <XCTest/XCTest.h>

#import <EarlGrey/EarlGrey.h>

@interface EarlGreyContribsTests : XCTestCase

@end

@implementation EarlGreyContribsTests

- (void)tearDown {
  [[EarlGrey selectElementWithMatcher:grey_anyOf(grey_text(@"EarlGreyContribTestApp"),
                                                 grey_text(@"Back"),
                                                 nil)]
      performAction:grey_tap()];
  [super tearDown];
}

- (void)testBasicViewController {
  [[[EarlGrey selectElementWithMatcher:grey_text(@"Basic Views")]
      usingSearchAction:grey_scrollInDirection(kGREYDirectionDown, 50)
      onElementWithMatcher:grey_kindOfClass([UITableView class])]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"textField")]
      performAction:grey_typeText(@"Foo")];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"showButton")]
      performAction:grey_tap()];
  [[EarlGrey selectElementWithMatcher:grey_accessibilityLabel(@"textLabel")]
      assertWithMatcher:grey_text(@"Foo")];
}

@end
