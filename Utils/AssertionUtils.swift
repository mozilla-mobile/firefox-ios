/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation

/**
 Assertion for checking that the call is being made on the main thread.

 - parameter message: Message to display in case of assertion.
 */
public func assertIsMainThread(message: String) {
    assert(NSThread.isMainThread(), message)
}