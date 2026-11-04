// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import QuickAnswersKit

@MainActor
final class MockNavigationHandler: QuickAnswersNavigationHandler {
    var dismissCallCount = 0
    var lastNavigationType: QuickAnswersNavigationType?
    var parkCallCount = 0
    var lastParkedNavigationType: QuickAnswersNavigationType?
    var bookmarkCallCount = 0
    var lastBookmarkedURL: URL?
    var lastBookmarkedTitle: String?

    func dismissQuickAnswers(with navigationType: QuickAnswersNavigationType?) {
        dismissCallCount += 1
        lastNavigationType = navigationType
    }

    func parkQuickAnswers(with navigationType: QuickAnswersNavigationType) {
        parkCallCount += 1
        lastParkedNavigationType = navigationType
    }

    func bookmarkCitation(url: URL, title: String) {
        bookmarkCallCount += 1
        lastBookmarkedURL = url
        lastBookmarkedTitle = title
    }
}
