// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

class ObservableCollectionViewCell: UICollectionViewCell {
    // MARK: Public config
    var visibilityDebugLabel = ""
    var isVisibilityMonitoringEnabled = false {
        didSet {
            if isVisibilityMonitoringEnabled {
                startObservingIfNeeded()
                checkVisibility()
            } else {
                stopObserving()
                resetVisibilityState()
                stopDwellTimer()
            }
        }
    }
    var visibilityFractionThreshold: CGFloat = 0.5
    var onBecomeVisible: ((ObservableCollectionViewCell) -> Void)?
    var dwellThresholdSeconds: TimeInterval = 1.0
    var onDwellMet: ((ObservableCollectionViewCell) -> Void)?

    // MARK: Visibility state
    var isVisible: Bool { visibleAreaFraction >= visibilityFractionThreshold }
    private var wasPreviouslyVisible = false

    // MARK: Dwell state
    private var dwellTimer: Timer?
    private var dwellFiredForThisLifetime = false

    // MARK: Visibility Logic
    private var observedScrollViews: Set<UIScrollView> = []

    private var visibleAreaFraction: CGFloat {
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
        resetVisibilityState()
        stopDwellTimer()
        super.prepareForReuse()
    }

    private func resetVisibilityState() {
        wasPreviouslyVisible = false
        dwellFiredForThisLifetime = false
    }

    override func layoutSubviews() {
        if isVisibilityMonitoringEnabled {
            startObservingIfNeeded()
            checkVisibility()
        }
        super.layoutSubviews()
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        // If the cell leaves the screen without prepareForReuse() being called we want to make sure we stop the timer
        if newWindow == nil {
            stopDwellTimer()
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
        checkVisibility()
    }

    private func checkVisibility() {
        let nowVisible = isVisible

        // Cell coming into view (not visible -> visible)
        if !wasPreviouslyVisible && nowVisible {
            onBecomeVisible?(self)
            startDwellTimerIfNeeded()
        }

        // Cell leaving view (visible -> not visible)
        if wasPreviouslyVisible && !nowVisible {
            stopDwellTimer()
        }

        wasPreviouslyVisible = nowVisible
    }

    // MARK: Dwell timer
    private func startDwellTimerIfNeeded() {
        guard dwellTimer == nil, !dwellFiredForThisLifetime else { return }
        let t = Timer(timeInterval: dwellThresholdSeconds, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            // Ensure still visible above threshold
            if self.isVisible && !self.dwellFiredForThisLifetime {
                self.dwellFiredForThisLifetime = true
                self.onDwellMet?(self)
            }
            self.stopDwellTimer()
        }
        t.tolerance = dwellThresholdSeconds * 0.1
        RunLoop.main.add(t, forMode: .common)
        dwellTimer = t
    }

    private func stopDwellTimer() {
        dwellTimer?.invalidate()
        dwellTimer = nil
    }
}
