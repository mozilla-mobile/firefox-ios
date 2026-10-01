// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit

/// Context containing all necessary information for layout calculations
struct LayoutContext {
    /// The root view size for the `SummarizeController`
    let viewSize: CGSize
    let traitCollection: UITraitCollection
    let tabSnapshotTopOffset: CGFloat

    var isLandscapeLayout: Bool {
        let size = viewSize
        // Use portrait layout when on iPad's regular size class
        return size.width > size.height && traitCollection.horizontalSizeClass != .regular
    }
}

/// Protocol for calculating the tab snapshot transforms for the different UI states
protocol SnapshotLayoutCalculator {
    /// Wether the interface was rotated
    var didRotateInterface: Bool { get set }

    /// Calculate transform for showing summary content
    func calculateSummaryTransform(context: LayoutContext) -> CGAffineTransform

    /// Calculate transform for showing error/info content
    func calculateInfoTransform(context: LayoutContext) -> CGAffineTransform

    /// Calculate transform for dismissing the view
    func calculateDismissTransform(context: LayoutContext) -> CGAffineTransform

    /// Calculate transform for the `viewDidAppear` state
    func calculateViewDidAppearTransform(context: LayoutContext) -> CGAffineTransform

    /// Calculate the transform for rotation state change
    func calculateDidRotateTransform(context: LayoutContext) -> CGAffineTransform
}

/// Default implementation of `SnapshotLayoutCalculator`
struct DefaultSnapshotLayoutCalculator: SnapshotLayoutCalculator {
    struct Configuration {
        let summaryTransformBottomPaddingPortrait: CGFloat
        let transformPercentagePortrait: CGFloat
        let transformPercentageLandscape: CGFloat

        static let `default` = Configuration(
            summaryTransformBottomPaddingPortrait: 110.0,
            transformPercentagePortrait: 0.5,
            transformPercentageLandscape: 1.0
        )
    }

    private let configuration: Configuration
    var didRotateInterface = false

    init(configuration: Configuration = .default) {
        self.configuration = configuration
    }

    func calculateSummaryTransform(context: LayoutContext) -> CGAffineTransform {
        guard !didRotateInterface else {
            return calculateDidRotateTransform(context: context)
        }
        if context.isLandscapeLayout {
            return CGAffineTransform(translationX: 0, y: context.viewSize.height)
        } else {
            let y = context.viewSize.height
                - configuration.summaryTransformBottomPaddingPortrait
                - context.tabSnapshotTopOffset
            return CGAffineTransform(translationX: 0, y: y)
        }
    }

    func calculateInfoTransform(context: LayoutContext) -> CGAffineTransform {
        guard !didRotateInterface else {
            return calculateDidRotateTransform(context: context)
        }
        let multiplier = context.isLandscapeLayout ?
        configuration.transformPercentageLandscape :
        configuration.transformPercentagePortrait
        return CGAffineTransform(translationX: 0, y: context.viewSize.height * multiplier)
    }

    func calculateDismissTransform(context: LayoutContext) -> CGAffineTransform {
        guard !didRotateInterface else {
            return calculateDidRotateTransform(context: context)
        }
        return .identity
    }

    func calculateViewDidAppearTransform(context: LayoutContext) -> CGAffineTransform {
        guard !didRotateInterface else {
            return calculateDidRotateTransform(context: context)
        }
        let multiplier = context.isLandscapeLayout ?
        configuration.transformPercentageLandscape :
        configuration.transformPercentagePortrait
        return CGAffineTransform(translationX: 0, y: context.viewSize.height * multiplier)
    }

    func calculateDidRotateTransform(context: LayoutContext) -> CGAffineTransform {
        // On rotation the transform invalidates the snapshot and moves it off screen
        return CGAffineTransform(translationX: 0.0, y: context.viewSize.height)
    }
}
