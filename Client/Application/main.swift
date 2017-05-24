/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Shared

private var appDelegate: AppDelegate.Type

if AppConstants.IsRunningTest {
    appDelegate = TestAppDelegate.self
} else {
    appDelegate = AppDelegate.self
}

private let pointer = UnsafeMutableRawPointer(CommandLine.unsafeArgv).bindMemory(to: UnsafeMutablePointer<Int8>.self, capacity: Int(CommandLine.argc))
UIApplicationMain(CommandLine.argc, pointer, NSStringFromClass(UIApplication.self), NSStringFromClass(appDelegate))
