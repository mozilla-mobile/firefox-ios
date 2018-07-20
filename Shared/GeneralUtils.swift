/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

// Wraps NimbleDroid to ensure it is disabled in release
// Use underscores between words, as these constants are stringified for reporting.
public class Profiler {
    public enum Bookend {
        case bvc_did_appear
        case url_autocomplete
        case intro_did_appear
        case history_panel_fetch
        case load_url
        case find_in_page
    }

    public static var shared: Profiler?

    private init() {}

    public static func appDidFinishLaunching() {
        assert(shared == nil)
        let args = ProcessInfo.processInfo.arguments
        if args.contains("nimbledroid") {
            shared = Profiler()
        }
    }

    public func appIsActive() {
        // Workaround: delay for a few ms so that ND profiler doesn't hang up
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.005) {
            Profiler.shared?.coldStartupEnd()
            Profiler.shared?.begin(bookend: .bvc_did_appear)
            Profiler.shared?.begin(bookend: .intro_did_appear)
        }
    }

    public func setup() {
        NDScenario.setup()
    }

    public func coldStartupEnd() {
        NDScenario.coldStartupEnd()
    }

    public func begin(bookend: Bookend) {
        NDScenario.begin(bookendID: "\(bookend)")
    }

    // This triggers a screenshot, and a delay is needed here in some cases to capture the correct screen
    // (otherwise the screen prior to this step completing is captured).
    public func end(bookend: Bookend, delay: TimeInterval = 0.0) {
        if delay > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                NDScenario.end(bookendID: "\(bookend)")
            }
        } else {
            NDScenario.end(bookendID: "\(bookend)")
        }
    }
}

/**
 Assertion for checking that the call is being made on the main thread.

 - parameter message: Message to display in case of assertion.
 */
public func assertIsMainThread(_ message: String) {
    assert(Thread.isMainThread, message)
}

// Simple timer for manual profiling. Not for production use.
// Prints only if timing is longer than a threshold (to reduce noisy output).
open class PerformanceTimer {
    let startTime: CFAbsoluteTime
    var endTime: CFAbsoluteTime?
    let threshold: Double
    let label: String

    public init(thresholdSeconds: Double = 0.001, label: String = "") {
        self.threshold = thresholdSeconds
        self.label = label
        startTime = CFAbsoluteTimeGetCurrent()
    }

    public func stopAndPrint() {
        if let t = stop() {
            print("Ran for \(t) seconds. [\(label)]")
        }
    }

    public func stop() -> String? {
        endTime = CFAbsoluteTimeGetCurrent()
        if let duration = duration {
            return "\(duration)"
        }
        return nil
    }

    public var duration: CFAbsoluteTime? {
        if let endTime = endTime {
            let time = endTime - startTime
            return time > threshold ? time : nil
        } else {
            return nil
        }
    }
}
