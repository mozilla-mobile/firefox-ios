// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared

private var appDelegate: String?

// For performance or UI tests, run the UITestAppDelegate
// For unit tests, run no app delegate as unit tests are testing enclosed units of code and shouldn't rely
// on App delegate for their setup and behavior
// For everything else, run the normal app delegate
if AppConstants.isRunningUITests || AppConstants.isRunningPerfTests {
    appDelegate = NSStringFromClass(UITestAppDelegate.self)
} else if AppConstants.isRunningTest {
    appDelegate = NSStringFromClass(UnitTestAppDelegate.self)
} else {
    appDelegate = NSStringFromClass(AppDelegate.self)
}

// Ignore SIGPIPE exceptions globally
// https://stackoverflow.com/questions/108183/how-to-prevent-sigpipes-or-handle-them-properly
signal(SIGPIPE, SIG_IGN)

_ = UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, NSStringFromClass(UIApplication.self), appDelegate)
