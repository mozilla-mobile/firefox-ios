// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import QuickAnswersKit

@MainActor
final class MockDismissable: QuickAnswersDismissable {
    var dismissCallCount = 0
    var lastURL: URL?

    func dismiss(with url: URL?) {
        dismissCallCount += 1
        lastURL = url
    }
}
