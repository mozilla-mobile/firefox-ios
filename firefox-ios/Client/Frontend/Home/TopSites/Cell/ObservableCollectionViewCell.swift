// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

/**
 A cell that can detect and react to changes in “in-view” and “visible” states using  area and time thresholds.

 We distinguish between "In-view" and "visible" as follows:
 - **In-view:**
        More than a given fraction (`inViewFractionThreshold`) of the cell’s area is unobscured in the viewport.
 - **Visible:**
        The cell remains in-view continuously for at least `visibleTimeThresholdSeconds`.
 Callbacks and configuration:
 - `onAboveInViewThreshold`:
        Callback that may fire multiple times over the cell’s lifetime. Called when the cell goes from !inView  to inView.
 - `onAboveVisibleTimeThreshold`:
        Callback that can fire only once over the cell’s lifetime. Called when the cell becomes visible as defined above.
 - `inViewFractionThreshold`:
        The fraction of the cell’s total area that must be unobscured in the viewport to count as in-view.
 - `visibleTimeThresholdSeconds`:
        The continuous time (in seconds) the cell must remain in-view to count as visible.
 - `isVisibilityMonitoringEnabled`:
        When `false`, the cell does not track in-view/visible state and behaves like a normal `UICollectionViewCell`.
 */
class ObservableCollectionViewCell: UICollectionViewCell {
    // MARK: Public config
    var visibilityDebugLabel = ""
    var isVisibilityMonitoringEnabled = false {
        didSet {
            if isVisibilityMonitoringEnabled {
                startObservingIfNeeded()
                checkIfCellIsInView()
            } else {
                stopObserving()
                stopVisibilityTimer()
                wasPreviouslyInView = false
            }
        }
    }
    var inViewFractionThreshold: CGFloat = 0.5
    var onAboveInViewThreshold: ((ObservableCollectionViewCell) -> Void)?
    var visibleTimeThresholdSeconds: TimeInterval = 1.0
    var onAboveVisibleTimeThreshold: ((ObservableCollectionViewCell) -> Void)?

    // MARK: In-view State
    var isInView: Bool { inViewAreaFraction >= inViewFractionThreshold }
    private var wasPreviouslyInView = false

    // MARK: Visibility State
    private var visibilityTimer: Timer?
    private var wasVisibleForThisLifetime = false

    // MARK: In-view Fraction Logic
    private var observedScrollViews: Set<UIScrollView> = []

    private var inViewAreaFraction: CGFloat {
        guard let window = window, !isHidden, alpha > 0.01, !bounds.isEmpty else { return 0 }
        var rect = convert(bounds, to: window).intersection(window.bounds)
        if rect.isNull { return 0 }
        var a = superview
        while let s = a, s !== window {
            if s.clipsToBounds {
                rect = rect.intersection(s.convert(s.bounds, to: window))
                if rect.isNull { return 0 }
            }
            a = s.superview
        }
        let total = bounds.width * bounds.height
        guard total > 0 else { return 0 }
        return max(0, min(1, (rect.width * rect.height) / total))
    }

    private var scrollViews: [UIScrollView] {
        let chain = sequence(first: superview, next: { $0?.superview })
        return Array(chain).compactMap { $0 as? UIScrollView }
    }

    // MARK: Lifecycle
    override func prepareForReuse() {
        stopObserving()
        stopVisibilityTimer()
        wasPreviouslyInView = false
        wasVisibleForThisLifetime = false
        super.prepareForReuse()
    }

    override func layoutSubviews() {
        if isVisibilityMonitoringEnabled {
            startObservingIfNeeded()
            checkIfCellIsInView()
        }
        super.layoutSubviews()
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        // If the cell leaves the screen without prepareForReuse() being called we want to make sure we stop the timer
        if newWindow == nil {
            stopVisibilityTimer()
        }
        super.willMove(toWindow: newWindow)
    }

    // MARK: Observing Logic
    private func startObservingIfNeeded() {
        for sv in scrollViews where !observedScrollViews.contains(sv) && isVisibilityMonitoringEnabled {
            sv.addObserver(self, forKeyPath: "contentOffset", context: nil)
            observedScrollViews.insert(sv)
        }
    }

    private func stopObserving() {
        for sv in observedScrollViews {
            sv.removeObserver(self, forKeyPath: "contentOffset")
        }
        observedScrollViews.removeAll()
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?,
                               change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard isVisibilityMonitoringEnabled, keyPath == "contentOffset" else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        checkIfCellIsInView()
    }

    private func checkIfCellIsInView() {
        let nowInView = isInView

        // Cell coming into view (not visible -> visible)
        if !wasPreviouslyInView && nowInView {
            onAboveInViewThreshold?(self)
            startVisibilityTimerIfNeeded()
        }

        // Cell leaving view (visible -> not visible)
        if wasPreviouslyInView && !nowInView {
            stopVisibilityTimer()
        }

        wasPreviouslyInView = nowInView
    }

    // MARK: Visibility timer
    private func startVisibilityTimerIfNeeded() {
        guard visibilityTimer == nil, !wasVisibleForThisLifetime else { return }
        let t = Timer(timeInterval: visibleTimeThresholdSeconds, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            // Ensure still visible above threshold
            if self.isInView && !self.wasVisibleForThisLifetime {
                self.wasVisibleForThisLifetime = true
                self.onAboveVisibleTimeThreshold?(self)
            }
            self.stopVisibilityTimer()
        }
        t.tolerance = visibleTimeThresholdSeconds * 0.1
        RunLoop.main.add(t, forMode: .common)
        visibilityTimer = t
    }

    private func stopVisibilityTimer() {
        visibilityTimer?.invalidate()
        visibilityTimer = nil
    }
}
