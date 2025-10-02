// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

class ObservableCollectionViewCell: UICollectionViewCell {

    var visibilityDebugLabel: String = ""
    var isVisibilityMonitoringEnabled: Bool = false
    var visibilityThreshold: CGFloat = 0.5
    var onBecomeVisible: ((ObservableCollectionViewCell) -> Void)?

    var isVisible: Bool { visibleAreaFraction >= visibilityThreshold }

    private var observedScrollViews: Set<UIScrollView> = []
    private var wasPreviouslyVisible: Bool = false

    private var visibleAreaFraction: CGFloat {
        guard let window = window, !isHidden, alpha > 0.01, !bounds.isEmpty
        else { return 0 }

        var visibleRect = convert(bounds, to: window)
        visibleRect = visibleRect.intersection(window.bounds)
        if visibleRect.isNull { return 0 }

        var ancestor = superview
        while let a = ancestor, a !== window {
            if a.clipsToBounds {
                let clip = a.convert(a.bounds, to: window)
                visibleRect = visibleRect.intersection(clip)
                if visibleRect.isNull { return 0 }
            }
            ancestor = a.superview
        }
        let visibleArea = visibleRect.width * visibleRect.height
        let totalArea = bounds.width * bounds.height
        guard totalArea > 0 else { return 0 }
        return max(0, min(1, visibleArea / totalArea))
    }

    private var scrollViews: [UIScrollView] {
        let superviews = Array(
            sequence(first: superview, next: { $0?.superview })
        )
        return superviews.filter({ $0 is UIScrollView }) as? [UIScrollView]
            ?? []
    }

    override func prepareForReuse() {
        for observedScrollView in observedScrollViews {
            observedScrollView.removeObserver(self, forKeyPath: "contentOffset")
        }

        observedScrollViews.removeAll()

        super.prepareForReuse()
    }

    override func layoutSubviews() {
        for scrollView in scrollViews {
            if !observedScrollViews.contains(scrollView)
                && isVisibilityMonitoringEnabled
            {
                scrollView.addObserver(
                    self,
                    forKeyPath: "contentOffset",
                    context: nil
                )
                observedScrollViews.insert(scrollView)
            }
        }

        checkVisibility()

        super.layoutSubviews()
    }

    private func checkVisibility() {
        if wasPreviouslyVisible != isVisible {
            print(
                "isVisible",
                visibilityDebugLabel,
                isVisible,
                visibleAreaFraction
            )
            onBecomeVisible?(self)
            wasPreviouslyVisible = isVisible
        }
    }

    private func stopObserving() {
        for sv in observedScrollViews {
            sv.removeObserver(self, forKeyPath: "contentOffset")
        }
        observedScrollViews.removeAll()
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        checkVisibility()
    }
}
