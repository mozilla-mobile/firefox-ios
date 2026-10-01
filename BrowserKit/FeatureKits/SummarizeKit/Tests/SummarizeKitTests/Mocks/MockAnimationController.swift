// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import SummarizeKit

final class MockAnimationController: AnimationController {
    var animateViewDidAppearCalled = 0
    var animateToSummaryCalled = 0
    var animateToInfoCalled = 0
    var animateToPanEndedCalled = 0
    var animateToDismissCalled = 0

    func animateViewDidAppear(
        snapshotTransform: CGAffineTransform,
        completion: @escaping () -> Void
    ) {
        animateViewDidAppearCalled += 1
        completion()
    }

    func animateToSummary(
        snapshotTransform: CGAffineTransform,
        applyTheme: @escaping () -> Void,
        completion: @escaping () -> Void
    ) {
        animateToSummaryCalled += 1
        completion()
    }

    func animateToInfo(
        snapshotTransform: CGAffineTransform,
        completion: @escaping () -> Void
    ) {
        animateToInfoCalled += 1
        completion()
    }

    func animateToPanEnded(snapshotTransform: CGAffineTransform) {
        animateToPanEndedCalled += 1
    }

    func animateToDismiss(
        snapshotTransform: CGAffineTransform,
        completion: @escaping () -> Void
    ) {
        animateToDismissCalled += 1
        completion()
    }
}
