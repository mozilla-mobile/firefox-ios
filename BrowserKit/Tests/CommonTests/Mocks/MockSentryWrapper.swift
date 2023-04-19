// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Sentry
import Common

class MockSentryWrapper: SentryWrapper {
    public var dsn: String?
    var mockCrashedInLastRun = false
    var startWithConfigureOptionsCalled = 0
    var savedMessage: String?
    var configureScopeCalled = 0
    var savedBreadcrumb: Breadcrumb?
    public var crashedInLastRun: Bool {
        return mockCrashedInLastRun
    }

    public func startWithConfigureOptions(configure options: @escaping (Options) -> Void) {
        startWithConfigureOptionsCalled += 1
    }

    public func captureMessage(message: String, with scopeBlock: @escaping (Scope) -> Void) {
        savedMessage = message
    }

    public func addBreadcrumb(crumb: Breadcrumb) {
        savedBreadcrumb = crumb
    }

    public func configureScope(scope: @escaping (Scope) -> Void) {
        configureScopeCalled += 1
    }
}
