// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

@testable import QuickAnswersKit

@MainActor
final class MockNavigationHandler: QuickAnswersNavigationHandler {
    var dismissCallCount = 0
    var lastNavigationType: QuickAnswersNavigationType?

    func dismissQuickAnswers(with navigationType: QuickAnswersNavigationType?) {
        dismissCallCount += 1
        lastNavigationType = navigationType
    }
}
