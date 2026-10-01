// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
@testable import SummarizeKit

final class MockSnapshotLayoutCalculator: SnapshotLayoutCalculator {
    var didRotateInterface = false
    var didCallCalculateSummaryTransform = 0
    var didCallCalculateInfoTransform = 0
    var didCallCalculateDismissTransform = 0
    var didCallCalculateViewDidAppearTransform = 0
    var didCallCalculateDidRotateTransform = 0

    func calculateSummaryTransform(context: SummarizeKit.LayoutContext) -> CGAffineTransform {
        didCallCalculateSummaryTransform += 1
        return .identity
    }

    func calculateInfoTransform(context: SummarizeKit.LayoutContext) -> CGAffineTransform {
        didCallCalculateInfoTransform += 1
        return .identity
    }

    func calculateDismissTransform(context: SummarizeKit.LayoutContext) -> CGAffineTransform {
        didCallCalculateDismissTransform += 1
        return .identity
    }

    func calculateViewDidAppearTransform(context: SummarizeKit.LayoutContext) -> CGAffineTransform {
        didCallCalculateViewDidAppearTransform += 1
        return .identity
    }

    func calculateDidRotateTransform(context: SummarizeKit.LayoutContext) -> CGAffineTransform {
        didCallCalculateDidRotateTransform += 1
        return .identity
    }
}
