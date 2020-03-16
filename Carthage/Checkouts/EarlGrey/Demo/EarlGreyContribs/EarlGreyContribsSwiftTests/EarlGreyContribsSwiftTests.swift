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

import EarlGrey
import XCTest

class EarlGreyContribsSwiftTests: XCTestCase {
  override func tearDown() {
    EarlGrey.selectElement(with: grey_anyOf([grey_text("EarlGreyContribTestApp"),
                                                    grey_text("Back")]))
      .perform(grey_tap())
    super.tearDown()
  }

  func testBasicViewController() {
    EarlGrey.selectElement(with: grey_text("Basic Views"))
      .usingSearch(grey_scrollInDirection(.down, 50),
        onElementWith: grey_kindOfClass(UITableView.self))
      .perform(grey_tap())
    EarlGrey.selectElement(with: grey_accessibilityLabel("textField"))
      .perform(grey_typeText("Foo"))
    EarlGrey.selectElement(with: grey_accessibilityLabel("showButton"))
      .perform(grey_tap())
    EarlGrey.selectElement(with: grey_accessibilityLabel("textLabel"))
      .assert(grey_text("Foo"))
  }

  func testCountOfTableViewCells() {
    var error: NSError? = nil
    let matcher: GREYMatcher! = grey_kindOfClass(UITableViewCell.self)
    let countOfTableViewCells: UInt = count(matcher: matcher)
    GREYAssert(countOfTableViewCells > 1, reason: "There are more than one cell present.")
    EarlGrey.selectElement(with: matcher)
      .atIndex(countOfTableViewCells + 1)
      .assert(grey_notNil(), error: &error)
    let errorCode: GREYInteractionErrorCode =
      GREYInteractionErrorCode.matchedElementIndexOutOfBoundsErrorCode
    let errorReason: String = "The Interaction element's index being used was over the count " +
    "of matched elements available."
    GREYAssert(error?.code == errorCode.rawValue, reason:errorReason)
  }
}

func count(matcher: GREYMatcher!) -> UInt {
  var error: NSError? = nil
  var index: UInt = 0
  let countMatcher: GREYElementMatcherBlock =
    GREYElementMatcherBlock.matcher(matchesBlock: { (element: Any) -> Bool in
      if (matcher.matches(element)) {
        index = index + 1;
      }
      return false;
    }) { (description: AnyObject?) in
      let greyDescription:GREYDescription = description as! GREYDescription
      greyDescription.appendText("Count of Matcher")
    }
  EarlGrey.selectElement(with: countMatcher)
    .assert(grey_notNil(), error: &error);
  return index
}

