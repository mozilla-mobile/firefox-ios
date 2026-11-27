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

    /// Polls for the element to exist. Returns `true` once it exists, or `false` on timeout.
    /// When `failOnTimeout` is `true` (default) a timeout records a test failure, with the poll
    /// figures, the web view state and the host load, and attaches the hierarchy.
    @discardableResult
    func mozWaitForElementToExist(timeout: TimeInterval? = TIMEOUT, failOnTimeout: Bool = true) -> Bool {
        let outcome = pollUntil(timeout: timeout) { exists }
        if !outcome.satisfied, failOnTimeout, let timeout = timeout {
            XCTFail("Timed out waiting for element \(self) to exist in \(timeout) seconds "
                    + "(\(timeoutDiagnostics(outcome.stats)))")
        }
        return outcome.satisfied
    }

    /// Polls for the element to stop existing. Returns `true` once it no longer exists, or `false`
    /// on timeout; with `failOnTimeout` (default) a timeout records a test failure.
    @discardableResult
    func mozWaitForElementToNotExist(timeout: TimeInterval? = TIMEOUT, failOnTimeout: Bool = true) -> Bool {
        let outcome = pollUntil(timeout: timeout) { !exists }
        if !outcome.satisfied, failOnTimeout {
            XCTFail("Timed out waiting for element \(self) to not exist "
                    + "(\(timeoutDiagnostics(outcome.stats)))")
        }
        return outcome.satisfied
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

    /// Waits until the element matches `predicate`, e.g. `value == 'x'` or `enabled == true`.
    /// Returns false on timeout instead of failing.
    @discardableResult
    func waitFor(_ predicate: NSPredicate, timeout: TimeInterval = TIMEOUT) -> Bool {
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    /// Waits until the element reports keyboard focus. Returns false on timeout instead of failing.
    @discardableResult
    func waitForKeyboardFocus(timeout: TimeInterval = TIMEOUT) -> Bool {
        let predicate = NSPredicate(format: "hasKeyboardFocus == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    /// Waits until the element no longer reports keyboard focus, since the editing overlay takes a
    /// moment to collapse. Returns false on timeout instead of failing.
    @discardableResult
    func waitUntilKeyboardFocusLost(timeout: TimeInterval = TIMEOUT) -> Bool {
        let predicate = NSPredicate(format: "hasKeyboardFocus == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    /// Waits until the element is hittable. Returns false on timeout instead of failing.
    @discardableResult
    func waitUntilHittable(timeout: TimeInterval = TIMEOUT) -> Bool {
        let predicate = NSPredicate(format: "exists == true && hittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    /// Waits until the element is gone. Returns false on timeout instead of failing.
    @discardableResult
    func waitUntilGone(timeout: TimeInterval = TIMEOUT) -> Bool {
        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    /// Waits until the element stops moving, since a tap synthesized against the mid-animation
    /// frame of a sheet lands on whatever sits under that point once the sheet has settled.
    @discardableResult
    func waitForFrameToSettle(timeout: TimeInterval = TIMEOUT) -> Bool {
        let startTime = Date()
        var previousFrame = frame
        while Date().timeIntervalSince(startTime) < timeout {
            usleep(100_000)
            let currentFrame = frame
            if currentFrame == previousFrame {
                return true
            }
            previousFrame = currentFrame
        }
        return false
    }

    /// Re-taps until `element` goes away, since a tap on a view that is presented as a form sheet
    /// is silently dropped while the sheet settles. Returns false instead of failing when it stays.
    @discardableResult
    func tapUntilElementDisappears(
        _ element: XCUIElement,
        timeout: TimeInterval? = TIMEOUT,
        disappearTimeout: TimeInterval = 5,
        tapAttempts: Int = 3
    ) -> Bool {
        self.mozWaitForElementToExist(timeout: timeout)
        var attempts = tapAttempts
        repeat {
            if !element.exists {
                return true
            }
            waitUntilHittable(timeout: disappearTimeout)
            self.tap(force: true)
            if element.waitUntilGone(timeout: disappearTimeout) {
                return true
            }
            attempts -= 1
        } while attempts > 0
        return !element.exists
    }

    /// Re-taps until the element reports keyboard focus, since a tap is swallowed while the
    /// keyboard animates. Returns false instead of failing when focus is never acquired.
    @discardableResult
    func tapUntilKeyboardFocused(
        timeout: TimeInterval? = TIMEOUT,
        focusTimeout: TimeInterval = 5,
        tapAttempts: Int = 3
    ) -> Bool {
        self.mozWaitForElementToExist(timeout: timeout)
        var attempts = tapAttempts
        repeat {
            if hasKeyboardFocus {
                return true
            }
            waitUntilHittable(timeout: focusTimeout)
            self.tap(force: true)
            if waitForKeyboardFocus(timeout: focusTimeout) {
                return true
            }
            attempts -= 1
        } while attempts > 0
        return hasKeyboardFocus
    }

    /// Taps and types text, but only once the field has keyboard focus.
    /// Returns false instead of failing when focus is never acquired, so callers can retry.
    @discardableResult
    func tapAndTypeTextWhenFocused(
        _ text: String,
        timeout: TimeInterval? = TIMEOUT,
        focusTimeout: TimeInterval = 5,
        tapAttempts: Int = 3
    ) -> Bool {
        guard tapUntilKeyboardFocused(timeout: timeout,
                                      focusTimeout: focusTimeout,
                                      tapAttempts: tapAttempts) else { return false }
        self.typeText(text)
        return true
    }

    /// Mean relative luminance of the element's on-screen pixels, from 0 (black) to 1 (white).
    func averageLuminance() -> Double {
        let pixels = sampledRGBAPixels()
        guard !pixels.isEmpty else { return 0 }
        var total = 0.0
        for offset in stride(from: 0, to: pixels.count, by: 4) {
            total += 0.2126 * Double(pixels[offset])
                + 0.7152 * Double(pixels[offset + 1])
                + 0.0722 * Double(pixels[offset + 2])
        }
        return total / Double(pixels.count / 4) / 255
    }

    /// Share of the element's on-screen pixels whose HSV saturation is above `threshold`, from 0 to 1.
    /// Near 0 means the element is drawn in grays or pale tints only.
    func saturatedPixelRatio(threshold: Double = 0.3) -> Double {
        shareOfPixels { _, saturation in saturation > threshold }
    }

    /// Share of the element's on-screen pixels, from 0 to 1, whose HSV hue in degrees falls in `hueRange`
    /// and whose saturation is above `minimumSaturation`.
    func shareOfPixels(inHueRange hueRange: ClosedRange<Double>, minimumSaturation: Double = 0.2) -> Double {
        shareOfPixels { hue, saturation in saturation > minimumSaturation && hueRange.contains(hue) }
    }

    /// Share of the sampled pixels for which `matches(hue, saturation)` holds; black pixels never match.
    private func shareOfPixels(matching matches: (Double, Double) -> Bool) -> Double {
        let pixels = sampledRGBAPixels()
        guard !pixels.isEmpty else { return 0 }
        var matching = 0
        for offset in stride(from: 0, to: pixels.count, by: 4) {
            let red = Double(pixels[offset]), green = Double(pixels[offset + 1]), blue = Double(pixels[offset + 2])
            let maximum = max(red, green, blue), minimum = min(red, green, blue)
            guard maximum > 0 else { continue }
            let delta = maximum - minimum
            var hue = 0.0
            if delta > 0 {
                if maximum == red {
                    hue = 60 * ((green - blue) / delta)
                } else if maximum == green {
                    hue = 60 * ((blue - red) / delta + 2)
                } else {
                    hue = 60 * ((red - green) / delta + 4)
                }
                if hue < 0 { hue += 360 }
            }
            if matches(hue, delta / maximum) { matching += 1 }
        }
        return Double(matching) / Double(pixels.count / 4)
    }

    /// The element's screenshot scaled down to `side` x `side` RGBA bytes, or empty if it can't be drawn.
    private func sampledRGBAPixels(side: Int = 32) -> [UInt8] {
        guard let image = screenshot().image.cgImage else { return [] }
        var pixels = [UInt8](repeating: 0, count: side * side * 4)
        let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(
                data: buffer.baseAddress,
                width: side,
                height: side,
                bitsPerComponent: 8,
                bytesPerRow: side * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: side, height: side))
            return true
        }
        return drawn ? pixels : []
    }

    /// Waits until `averageLuminance()` satisfies `condition`. Returns false on timeout instead of failing.
    @discardableResult
    func waitForLuminance(timeout: TimeInterval = TIMEOUT, _ condition: @escaping (Double) -> Bool) -> Bool {
        let predicate = NSPredicate { _, _ in condition(self.averageLuminance()) }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    /// Waits for the label to start with `prefix` and returns the whole number right after it, ignoring
    /// grouping separators ("5,305"). Returns nil on timeout or when no number follows the prefix.
    func wholeNumberInLabel(after prefix: String = "", timeout: TimeInterval = TIMEOUT) -> Int? {
        // BEGINSWITH never matches an empty string, so with no prefix any non-empty label will do
        let hasPrefix = prefix.isEmpty
            ? NSPredicate(format: "label != ''")
            : NSPredicate(format: "label BEGINSWITH %@", prefix)
        let expectation = XCTNSPredicateExpectation(predicate: hasPrefix, object: self)
        guard XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed else { return nil }
        let number = label.dropFirst(prefix.count).prefix { $0.isNumber || $0.isPunctuation || $0.isWhitespace }
        return Int(String(number.filter(\.isNumber)))
    }
}

// MARK: - Polling with the figures a timeout message needs

/// Figures from one polling loop, for timeout messages.
struct PollStats {
    var polls = 0
    var elapsed: TimeInterval = 0
    var slowestPoll: TimeInterval = 0
    var totalPollTime: TimeInterval = 0

    var summary: String {
        let mean = polls == 0 ? 0 : totalPollTime / Double(polls)
        return String(
            format: "%d polls in %.1f s, each %.0f ms on average and %.0f ms at worst",
            polls,
            elapsed,
            mean * 1000,
            slowestPoll * 1000
        )
    }
}

/// Polls `condition` every 10 ms until it holds or `timeout` elapses (never, when `timeout` is nil),
/// timing each call.
func pollUntil(timeout: TimeInterval?, _ condition: () -> Bool) -> (satisfied: Bool, stats: PollStats) {
    var stats = PollStats()
    let start = Date()
    while true {
        let pollStart = Date()
        let satisfied = condition()
        let pollTime = Date().timeIntervalSince(pollStart)
        stats.polls += 1
        stats.totalPollTime += pollTime
        stats.slowestPoll = max(stats.slowestPoll, pollTime)
        stats.elapsed = Date().timeIntervalSince(start)
        if satisfied { return (true, stats) }
        if let timeout = timeout, stats.elapsed > timeout { return (false, stats) }
        usleep(10000)
    }
}

/// A poll longer than this ran into XCTest's own 30 s query timeout: the automation session is not answering.
let pollTimeThatMeansTheSessionIsNotAnswering: TimeInterval = 20

/// Poll figures, web view state and host load for a timeout message, with the hierarchy attached;
/// skips the snapshots when the session is not answering.
@MainActor
func timeoutDiagnostics(_ stats: PollStats, in app: XCUIApplication = XCUIApplication()) -> String {
    guard stats.slowestPoll < pollTimeThatMeansTheSessionIsNotAnswering else {
        return "\(stats.summary); hierarchy and web view not inspected because a poll took "
            + String(format: "%.0f s: the automation session is not answering; ", stats.slowestPoll)
            + hostLoadSummary()
    }
    attachHierarchyAtTimeout(of: app)
    return "\(stats.summary); \(webContentSummary(in: app)); \(hostLoadSummary())"
}

/// Whether a web view is on screen and how many accessibility elements it exposes. Costs two snapshots.
@MainActor
func webContentSummary(in app: XCUIApplication = XCUIApplication()) -> String {
    let webView = app.webViews.firstMatch
    guard webView.exists else { return "no web view on screen" }
    let count = webView.descendants(matching: .any).count
    return "web view on screen exposing \(count) accessibility element\(count == 1 ? "" : "s")"
}

struct HostLoad {
    let oneMinute: Double
    let fiveMinutes: Double
    let fifteenMinutes: Double
}

/// The Mac's load averages (the runner is a host process); nil if the call fails.
func hostLoadAverages() -> HostLoad? {
    var loads = [Double](repeating: 0, count: 3)
    guard getloadavg(&loads, 3) == 3 else { return nil }
    return HostLoad(oneMinute: loads[0], fiveMinutes: loads[1], fifteenMinutes: loads[2])
}

/// One line with the host's load averages and core count.
func hostLoadSummary() -> String {
    let cores = ProcessInfo.processInfo.activeProcessorCount
    guard let loads = hostLoadAverages() else { return "host load unavailable" }
    return String(
        format: "host load %.1f/%.1f/%.1f on %d cores",
        loads.oneMinute,
        loads.fiveMinutes,
        loads.fifteenMinutes,
        cores
    )
}

/// Attaches the hierarchy XCTest was seeing when a wait gave up, next to the automatic screenshot.
@MainActor
func attachHierarchyAtTimeout(of app: XCUIApplication = XCUIApplication()) {
    XCTContext.runActivity(named: "Hierarchy at timeout") { activity in
        let attachment = XCTAttachment(string: app.debugDescription)
        attachment.name = "hierarchy at timeout"
        attachment.lifetime = .keepAlways
        activity.add(attachment)
    }
}
