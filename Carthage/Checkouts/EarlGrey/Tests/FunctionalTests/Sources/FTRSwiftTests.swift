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

class TextFieldEventsRecorder {
  var textDidBeginEditing = false
  var textDidChange = false
  var textDidEndEditing = false
  var editingDidBegin = false
  var editingChanged = false
  var editingDidEndOnExit = false
  var editingDidEnd = false

  func registerActionBlock() -> GREYActionBlock {
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(textDidBeginEditingHandler),
                                           name: NSNotification.Name.UITextFieldTextDidBeginEditing,
                                           object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(textDidChangeHandler),
                                           name: NSNotification.Name.UITextFieldTextDidChange,
                                           object: nil)
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(textDidEndEditingHandler),
                                           name: NSNotification.Name.UITextFieldTextDidEndEditing,
                                           object: nil)
    return GREYActionBlock.action(withName: "Register to editing events") {
      (element: Any?, errorOrNil: UnsafeMutablePointer<NSError?>?) -> Bool in
      let element:UIControl = element as! UIControl
      element.addTarget(self,
                        action: #selector(self.editingDidBeginHandler), for: .editingDidBegin)
      element.addTarget(self,
                        action: #selector(self.editingChangedHandler), for: .editingChanged)
      element.addTarget(self,
                        action: #selector(self.editingDidEndOnExitHandler),
                        for: .editingDidEndOnExit)
      element.addTarget(self,
                        action: #selector(self.editingDidEndHandler), for: .editingDidEnd)
      return true
    }
  }

  func verify() -> Bool {
    return textDidBeginEditing && textDidChange && textDidEndEditing &&
      editingDidBegin && editingChanged && editingDidEndOnExit && editingDidEnd
  }

  @objc func textDidBeginEditingHandler() { textDidBeginEditing = true }
  @objc func textDidChangeHandler() { textDidChange = true }
  @objc func textDidEndEditingHandler() { textDidEndEditing = true }
  @objc func editingDidBeginHandler() { editingDidBegin = true }
  @objc func editingChangedHandler() { editingChanged = true }
  @objc func editingDidEndOnExitHandler() { editingDidEndOnExit = true }
  @objc func editingDidEndHandler() { editingDidEnd = true }
}

class FTRSwiftTests: XCTestCase {

  override func tearDown() {
    super.tearDown()
    let delegateWindow:UIWindow! = UIApplication.shared.delegate!.window!
    var navController:UINavigationController?
    if ((delegateWindow.rootViewController?.isKind(of: UINavigationController.self)) != nil) {
      navController = delegateWindow.rootViewController as? UINavigationController
    } else {
      navController = delegateWindow.rootViewController!.navigationController
    }
    _ = navController?.popToRootViewController(animated: true)
  }

  func testOpeningView() {
    self.openTestView("Typing Views")
  }

  func testRotation() {
    EarlGrey.rotateDeviceTo(orientation: UIDeviceOrientation.landscapeLeft, errorOrNil: nil)
    EarlGrey.rotateDeviceTo(orientation: UIDeviceOrientation.portrait, errorOrNil: nil)
  }

  func testTyping() {
    self.openTestView("Typing Views")
    let matcher = grey_accessibilityID("TypingTextField")
    let action = grey_typeText("Sample Swift Test")
    let assertionMatcher = grey_text("Sample Swift Test")
    EarlGrey.selectElement(with: matcher)
      .perform(action)
      .assert(assertionMatcher)
  }

  func testTypingWithError() {
    self.openTestView("Typing Views")
    EarlGrey.selectElement(with: grey_accessibilityID("TypingTextField"))
      .perform(grey_typeText("Sample Swift Test"))
      .assert(grey_text("Sample Swift Test"))

    var error: NSError?
    EarlGrey.selectElement(with: grey_accessibilityID("TypingTextField"))
      .perform(grey_typeText(""), error: &error)
      .assert(grey_text("Sample Swift Test"), error: nil)
    GREYAssert(error != nil, reason: "Performance should have errored")
    error = nil
    EarlGrey.selectElement(with: grey_accessibilityID("TypingTextField"))
      .perform(grey_clearText())
      .perform(grey_typeText("Sample Swift Test"), error: nil)
      .assert(grey_text("Garbage Value"), error: &error)
    GREYAssert(error != nil, reason: "Performance should have errored")
  }

  func testFastTyping() {
    self.openTestView("Typing Views")
    let textFieldEventsRecorder = TextFieldEventsRecorder()
    EarlGrey.selectElement(with: grey_accessibilityID("TypingTextField"))
      .perform(textFieldEventsRecorder.registerActionBlock())
      .perform(grey_replaceText("Sample Swift Test"))
      .assert(grey_text("Sample Swift Test"))
    GREYAssert(textFieldEventsRecorder.verify(), reason: "Text field events were not all received")
  }

  func testTypingWithDeletion() {
    self.openTestView("Typing Views")
    EarlGrey.selectElement(with: grey_accessibilityID("TypingTextField"))
      .perform(grey_typeText("Fooo\u{8}B\u{8}Bar"))
      .assert(grey_text("FooBar"))
  }

  func testButtonPressWithGREYAllOf() {
    self.openTestView("Basic Views")
    EarlGrey.selectElement(with: grey_text("Tab 2")).perform(grey_tap())
    let matcher = grey_allOf([grey_text("Long Press"), grey_sufficientlyVisible()])
    EarlGrey.selectElement(with: matcher).perform(grey_longPressWithDuration(1.1))
      .assert(grey_notVisible())
  }

  func testPossibleOpeningViews() {
    self.openTestView("Alert Views")
    let matcher = grey_anyOf([grey_text("FooText"),
                              grey_text("Simple Alert"),
                              grey_buttonTitle("BarTitle")])
    EarlGrey.selectElement(with: matcher).perform(grey_tap())
    EarlGrey.selectElement(with: grey_text("Flee"))
      .assert(grey_sufficientlyVisible())
      .perform(grey_tap())
  }

  func testSwiftCustomMatcher() {
    // Verify description in custom matcher isn't nil.
    // unexpectedly found nil while unwrapping an Optional value
    EarlGrey.selectElement(with: grey_allOf([grey_firstElement(),
                                                    grey_text("FooText")]))
      .assert(grey_nil())
  }

  func testInteractionWithALabelWithParentHidden() {
    let checkHiddenBlock:GREYActionBlock =
      GREYActionBlock.action(withName: "checkHiddenBlock", perform: { element, errorOrNil in
        // Check if the found element is hidden or not.
        let superView:UIView! = element as! UIView
        return !superView.isHidden
      })

    self.openTestView("Basic Views")
    EarlGrey.selectElement(with: grey_text("Tab 2")).perform(grey_tap())
    EarlGrey.selectElement(with: grey_accessibilityLabel("tab2Container"))
      .perform(checkHiddenBlock).assert(grey_sufficientlyVisible())
    var error: NSError?
    EarlGrey.selectElement(with: grey_text("Non Existent Element"))
      .perform(grey_tap(), error:&error)
    if let errorVal = error {
      GREYAssertEqual(errorVal.domain as AnyObject?, kGREYInteractionErrorDomain as AnyObject?,
                      reason: "Element Not Found Error")
    }
  }

  func testChangingDatePickerToAFutureDate() {
    self.openTestView("Picker Views")
    // Have an arbitrary date created
    let dateFormatter = DateFormatter()
    dateFormatter.dateStyle = .medium
    let date = Date(timeIntervalSinceReferenceDate: 118800)
    dateFormatter.locale = Locale(identifier: "en_US")
    EarlGrey.selectElement(with: grey_text("Date")).perform(grey_tap())
    EarlGrey.selectElement(with: grey_accessibilityID("DatePickerId"))
      .perform(grey_setDate(date))
    EarlGrey.selectElement(with: grey_accessibilityID("DatePickerId"))
      .assert(grey_datePickerValue(date))
  }

  func testStepperActionWithCondition() {
    self.openTestView("Basic Views")
    var stepperValue = 51.0
    // Without the parameter using the value of the wait action, a warning should be seen.
    _ = GREYCondition.init(name: "conditionWithAction", block: {
      stepperValue += 1
      EarlGrey.selectElement(with: grey_kindOfClass(UIStepper.self))
        .perform(grey_setStepperValue(stepperValue))
      return stepperValue == 55
    }).waitWithTimeout(seconds: 10.0)
    EarlGrey.selectElement(with: grey_kindOfClass(UIStepper.self))
      .assert(grey_stepperValue(55))
  }

  func openTestView(_ name: String) {
    var errorOrNil : NSError?
    EarlGrey.selectElement(with: grey_accessibilityLabel(name))
      .perform(grey_tap(), error: &errorOrNil)
    if ((errorOrNil == nil)) {
      return
    }
    EarlGrey.selectElement(with: grey_kindOfClass(UITableView.self))
      .perform(grey_scrollToContentEdge(GREYContentEdge.top))
    EarlGrey.selectElement(with: grey_allOf([grey_accessibilityLabel(name),
                                                    grey_interactable()]))
      .using(searchAction: grey_scrollInDirection(GREYDirection.down, 200),
             onElementWithMatcher: grey_kindOfClass(UITableView.self))
      .perform(grey_tap())
  }

  func grey_firstElement() -> GREYMatcher {
    var firstMatch = true
    let matches: MatchesBlock = { (element: Any) -> Bool in
      if firstMatch {
        firstMatch = false
        return true
      }

      return false
    }

    let describe: DescribeToBlock = { (description: GREYDescription?) -> Void in
      description!.appendText("first match")
    }

    return GREYElementMatcherBlock.init(matchesBlock: matches, descriptionBlock: describe)
  }
}
