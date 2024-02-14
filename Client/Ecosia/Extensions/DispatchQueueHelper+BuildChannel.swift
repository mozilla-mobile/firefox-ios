// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

/// Executes a block of code on the main thread.
///
/// - If the build channel is `.release`, the block is executed immediately.
/// - Otherwise, it is executed after a specified delay. This might be useful for QA testing.
///
/// - Parameters:
///   - work: A closure to be executed on the main thread.
///   - delay: The time interval (in seconds) to delay the execution if the build channel is not `.release`. The default value is 5.0 seconds.
public func executeOnMainThreadWithDelayForNonReleaseBuild(execute work: @escaping @convention(block) () -> Swift.Void,
                                                           delayedBy delay: TimeInterval = 5.0) {
    if BrowserKitInformation.shared.buildChannel == .release {
        work()
    } else {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            work()
        }
    }
}
