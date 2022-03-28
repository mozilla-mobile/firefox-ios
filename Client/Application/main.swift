// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import Shared

private var appDelegate: AppDelegate.Type

if AppConstants.IsRunningTest || AppConstants.IsRunningPerfTest {
    appDelegate = TestAppDelegate.self
} else {
    appDelegate = AppDelegate.self
}

// Ignore SIGPIPE exceptions globally
// https://stackoverflow.com/questions/108183/how-to-prevent-sigpipes-or-handle-them-properly
signal(SIGPIPE, SIG_IGN)

_ = UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, NSStringFromClass(UIApplication.self), NSStringFromClass(appDelegate))
