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

_ = UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, NSStringFromClass(UIApplication.self), NSStringFromClass(appDelegate))
