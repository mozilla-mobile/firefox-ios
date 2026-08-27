// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AVFoundation
import Common
import Foundation
import Shared
import WebKit

/// Keeps audio/video playing when the app enters the background.
///
/// On `willResignActive`, tags every media element that is currently playing.
/// On `didEnterBackground`, lifts automatic media suspension and
/// resumes the previously-playing elements.
@MainActor
class BackgroundAudioHelper: Notifiable {
    static let shared = BackgroundAudioHelper()

    private var isObserving = false
    private let notificationCenter: NotificationProtocol

    private static let observedNotifications: [Notification.Name] = [
        UIApplication.willResignActiveNotification,
        UIApplication.didEnterBackgroundNotification,
        UIApplication.didBecomeActiveNotification
    ]

    private static let tagPlayingMediaJS = """
        document.querySelectorAll('video,audio').forEach(el => {
            el.dataset.wasPlaying = (!el.paused).toString();
        });
        """

    private static let resumeTaggedMediaJS = """
        document.querySelectorAll('[data-was-playing="true"]').forEach(el => {
            el.play();
            delete el.dataset.wasPlaying;
        });
        """

    private static let applyVisibilityOverridesJS = """
        window.__firefoxBlockVisibilityChange = true;
        Object.defineProperty(document, 'hidden', { get: () => false, configurable: true });
        Object.defineProperty(document, 'visibilityState', { get: () => 'visible', configurable: true });
        """

    private static let removeVisibilityOverridesJS = """
        window.__firefoxBlockVisibilityChange = false;
        delete document.hidden;
        delete document.visibilityState;
        """

    init(notificationCenter: NotificationProtocol = NotificationCenter.default) {
        self.notificationCenter = notificationCenter
    }

    static func isEnabled(_ prefs: Prefs) -> Bool {
        let nimbusDefault = FxNimbus.shared.features.backgroundAudioFeature.value().defaultOn
        return prefs.boolForKey(PrefsKeys.BackgroundAudio) ?? nimbusDefault
    }

    func configure(prefs: Prefs) {
        guard Self.isEnabled(prefs) else { return }
        startObserving()
    }

    func toggle(isEnabled: Bool, prefs: Prefs) {
        prefs.setBool(isEnabled, forKey: PrefsKeys.BackgroundAudio)
        if isEnabled {
            startObserving()
        } else {
            stopObserving()
        }
    }

    func startObserving() {
        guard !isObserving else { return }
        isObserving = true
        startObservingNotifications(
            withNotificationCenter: notificationCenter,
            forObserver: self,
            observing: Self.observedNotifications
        )
    }

    func stopObserving() {
        guard isObserving else { return }
        isObserving = false
        stopObservingNotifications(
            withNotificationCenter: notificationCenter,
            forObserver: self,
            observing: Self.observedNotifications
        )
    }

    nonisolated func handleNotifications(_ notification: Notification) {
        let name = notification.name
        ensureMainThread { [weak self] in
            switch name {
            case UIApplication.willResignActiveNotification:
                self?.handleWillResignActive()
            case UIApplication.didEnterBackgroundNotification:
                self?.resumeTaggedMedia()
            case UIApplication.didBecomeActiveNotification:
                self?.handleDidBecomeActive()
            default:
                break
            }
        }
    }

    private func handleWillResignActive() {
        try? AVAudioSession.sharedInstance().setCategory(.playback)
        for webView in Self.selectedTabWebViews() {
            webView.evaluateJavaScript(Self.tagPlayingMediaJS)
        }
    }

    private func handleDidBecomeActive() {
        try? AVAudioSession.sharedInstance().setCategory(.soloAmbient)
        for webView in Self.selectedTabWebViews() {
            webView.evaluateJavaScript(Self.removeVisibilityOverridesJS, in: nil, in: .page)
        }
    }

    private func resumeTaggedMedia() {
        for webView in Self.selectedTabWebViews() {
            webView.evaluateJavaScript(Self.applyVisibilityOverridesJS, in: nil, in: .page)
            webView.setAllMediaPlaybackSuspended(false) {
                webView.evaluateJavaScript(Self.resumeTaggedMediaJS)
            }
        }
    }

    private static func selectedTabWebViews() -> [WKWebView] {
        let windowManager: WindowManager = AppContainer.shared.resolve()
        return windowManager.allWindowTabManagers().compactMap { $0.selectedTab?.webView }
    }
}
