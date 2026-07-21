// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

/// Shared between the XCUITests and L10nSnapshotTests targets (added to both targets' Sources
/// build phase) since they don't otherwise share a base test case class.
extension XCUIElement {
    func tap(force: Bool) {
        // There appears to be a bug with tapping elements sometimes, despite them being on-screen
        // and tappable, due to hittable being false.
        // See: http://stackoverflow.com/a/33534187/1248491
        if isHittable {
            tap()
        } else if force {
            coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }

    func tapIfExists(timeout: TimeInterval = 5.0) {
        if mozWaitForElementToExist(timeout: timeout, failOnTimeout: false) {
            self.tap()
        }
    }

    /// Tap at @offsetPoint point in @self element view. This might not work for simulators lower than iPhone 14 Plus.
    func tapAtPoint(_ offsetPoint: CGPoint) {
        self.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
            .withOffset(CGVector(dx: offsetPoint.x, dy: offsetPoint.y))
            .tap()
    }

    /// Press at @offsetPoint point in @self element view
    func pressAtPoint(_ offsetPoint: CGPoint, forDuration duration: TimeInterval) {
        self.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
            .withOffset(CGVector(dx: offsetPoint.x, dy: offsetPoint.y))
            .press(forDuration: duration)
    }

    /// Check the position of one XCUIElement is on the left side of another XCUIElement
    func isLeftOf(rightElement: XCUIElement) -> Bool {
        return self.frame.origin.x < rightElement.frame.origin.x
    }

    /// Check the position of one XCUIElement is on the right side of another XCUIElement
    func isRightOf(rightElement: XCUIElement) -> Bool {
        return self.frame.origin.x > rightElement.frame.origin.x
    }

    /// Check the position of two XCUIElement objects on vertical line
    /// - parameter element: XCUIElement
    /// - distance: the max distance accepted between them
    /// - return Bool: if the current object is above the given object
    func isAbove(element: XCUIElement, maxDistanceBetween: CGFloat = 700) -> Bool {
        let isAbove = self.frame.origin.y < element.frame.origin.y
        let actualDistance = abs(self.frame.origin.y - element.frame.origin.y)
        return isAbove && (actualDistance < maxDistanceBetween)
    }

    /// Check the position of two XCUIElement objects on vertical line
    /// - parameter element: XCUIElement
    /// - distance: the max distance accepted between them
    /// - return Bool: if the current object is below the given object
    func isBelow(element: XCUIElement, maxDistanceBetween: CGFloat = 700) -> Bool {
        let isBelow = self.frame.origin.y > element.frame.origin.y
        let actualDistance = abs(self.frame.origin.y - element.frame.origin.y)
        return isBelow && (actualDistance < maxDistanceBetween)
    }

    fileprivate func getVisibleScreenFrame(app: XCUIElement = XCUIApplication()) -> CGRect {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        return springboard.frame
    }

    func isValidRectangle(_ rectangle: CGRect) -> Bool {
        if !rectangle.isNull && rectangle != CGRect(x: 0, y: 0, width: 0, height: 0) {
            // the intersection area should be >= 0
            return rectangle.width * rectangle.height >= 0
        }
        return false
    }

    /// Returns true if @rectangleToBeIncluded area is partially included in @rectangleArea area.
    func isPartiallyIncluded(rectangleArea: CGRect, rectangleToBeIncluded: CGRect) -> Bool {
        let intersection = rectangleArea.intersection(rectangleToBeIncluded)
        return isValidRectangle(intersection)
    }

    /// Check if the current UI element is fully or partially visible.
    func isVisible(app: XCUIApplication = XCUIApplication()) -> Bool {
        let visibleScreenFrame = getVisibleScreenFrame(app: app)
        return self.exists && isPartiallyIncluded(rectangleArea: visibleScreenFrame, rectangleToBeIncluded: self.frame)
    }

    func tapWithRetry() {
        waitAndTap()
        var nrOfTaps = 5
        while self.isHittable && nrOfTaps > 0 {
            tap(force: true)
            nrOfTaps -= 1
        }
        if self.isHittable {
            XCTFail("\(self) was not tapped")
        }
    }

    func typeTextWithDelay(_ text: String, delay: TimeInterval) {
        for character in text {
            self.typeText(String(character))
            Thread.sleep(forTimeInterval: delay)
        }
    }

    // Swipe up a little less than half the element
    func partialSwipeUp(distance: CGFloat = 0.5) {
        let elementBounds = self.frame
        let centerX = elementBounds.width/2
        let centerY = elementBounds.height/2
        // Start coordinate about from the center of the element, end coordinate at the top
        let startCoordinate = coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
            .withOffset(CGVector(dx: centerX, dy: centerY))
        let endCoordinate = coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
            .withOffset(CGVector(dx: centerX, dy: centerY - (elementBounds.size.height/2) * distance))
        startCoordinate.press(forDuration: 0, thenDragTo: endCoordinate)
    }

    // Swipe down a little less than half the element
    func partialSwipeDown(distance: CGFloat = 0.5) {
        let elementBounds = self.frame
        let centerX = elementBounds.width/2
        let centerY = elementBounds.height/2
        // Start coordinate about from the center of the element, end coordinate at the bottom
        // Done rather than top to middle to avoid pulling down the notification bar
        let startCoordinate = coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
            .withOffset(CGVector(dx: centerX, dy: centerY))
        let endCoordinate = coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
            .withOffset(CGVector(dx: centerX, dy: centerY + (elementBounds.size.height/2) * distance))
        startCoordinate.press(forDuration: 0, thenDragTo: endCoordinate)
    }

    func tapOnApp() {
        coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    func mozWaitElementHittable(timeout: Double) {
        let predicate = NSPredicate(format: "exists == true && hittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        let result = XCTWaiter().wait(for: [expectation], timeout: timeout)
        XCTAssertEqual(result, .completed, "Element did not become hittable in time.")
    }

    @discardableResult
    func mozWaitForElementToExist(timeout: TimeInterval? = TIMEOUT, failOnTimeout: Bool = true) -> Bool {
        let startTime = Date()
        while !exists {
            if let timeout = timeout, Date().timeIntervalSince(startTime) > timeout {
                if failOnTimeout {
                    XCTFail("Timed out waiting for element \(self) to exist in \(timeout) seconds")
                }
                return false
            }
            usleep(10000)
        }
        return true
    }

    /// Waits for the UI element and then taps if it exists.
    func waitAndTap(timeout: TimeInterval? = TIMEOUT) {
        self.mozWaitForElementToExist(timeout: timeout)
        self.tap()
    }

    /// Waits for the UI element and then taps and types the provided text if it exists.
    func tapAndTypeText(_ text: String, timeout: TimeInterval? = TIMEOUT) {
        self.mozWaitForElementToExist(timeout: timeout)
        self.tap()
        self.typeText(text)
    }

    func pressWithRetry(duration: TimeInterval, timeout: TimeInterval = TIMEOUT, element: XCUIElement) {
        self.mozWaitForElementToExist(timeout: timeout)
        self.press(forDuration: duration)
        if element.mozWaitForElementToExist(timeout: 1.0, failOnTimeout: false) {
            return
        }
        var attempts = 5
        while !element.exists && attempts > 0 {
            self.press(forDuration: duration)
            if element.mozWaitForElementToExist(timeout: 1.0, failOnTimeout: false) {
                return
            }
            attempts -= 1
        }

        if !element.exists {
            XCTFail("\(element) is not visible after \(attempts) attempts")
        }
    }

    /// Whether the element currently holds keyboard focus, read via KVC on the accessibility snapshot.
    var hasKeyboardFocus: Bool {
        return (self.value(forKey: "hasKeyboardFocus") as? Bool) ?? false
    }

    /// Waits until the element reports keyboard focus. Returns false on timeout instead of failing.
    @discardableResult
    func waitForKeyboardFocus(timeout: TimeInterval = TIMEOUT) -> Bool {
        let predicate = NSPredicate(format: "hasKeyboardFocus == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    /// Taps and types text, but only once the field has keyboard focus.
    ///
    /// On CI some fields (the springboard passcode overlay, the address bar) are occasionally
    /// presented without keyboard focus, so a plain `typeText` raises "Neither element nor any
    /// descendant has keyboard focus" and aborts the test. This re-taps up to `tapAttempts` times
    /// until focus is acquired before typing, and returns false (rather than failing hard) if it
    /// never is, so callers can retry.
    @discardableResult
    func tapAndTypeTextWhenFocused(
        _ text: String,
        timeout: TimeInterval? = TIMEOUT,
        focusTimeout: TimeInterval = 5,
        tapAttempts: Int = 3
    ) -> Bool {
        self.mozWaitForElementToExist(timeout: timeout)
        var attempts = tapAttempts
        repeat {
            if !hasKeyboardFocus {
                self.tap()
            }
            if waitForKeyboardFocus(timeout: focusTimeout) {
                self.typeText(text)
                return true
            }
            attempts -= 1
        } while attempts > 0
        return false
    }
}
