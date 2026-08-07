// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import AVFoundation
import Common
import Foundation
import Shared

@MainActor
class BackgroundAudioHelper {
    nonisolated(unsafe) private static var observers: [NSObjectProtocol] = []

    static func isEnabled(_ prefs: Prefs) -> Bool {
        return prefs.boolForKey(PrefsKeys.BackgroundAudio) ?? false
    }

    static func configure(prefs: Prefs) {
        if isEnabled(prefs) {
            start()
        }
    }

    static func toggle(isEnabled: Bool, prefs: Prefs) {
        prefs.setBool(isEnabled, forKey: PrefsKeys.BackgroundAudio)
        if isEnabled {
            start()
        } else {
            stop()
        }
    }

    private static func start() {
        try? AVAudioSession.sharedInstance().setCategory(.playback)

        guard observers.isEmpty else { return }

        // Before WebKit suspends media, tag elements that are currently playing
        let willResign = NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            let windowManager: WindowManager = AppContainer.shared.resolve()
            for tm in windowManager.allWindowTabManagers() {
                guard let webView = tm.selectedTab?.webView else { continue }
                webView.evaluateJavaScript(
                    "document.querySelectorAll('video,audio').forEach(e=>{e.dataset.wasPlaying=(!e.paused).toString()})"
                )
            }
        }

        // After backgrounding, unsuspend WebKit media and resume only what was playing
        let didBackground = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { _ in
            let windowManager: WindowManager = AppContainer.shared.resolve()
            for tm in windowManager.allWindowTabManagers() {
                guard let webView = tm.selectedTab?.webView else { continue }
                webView.setAllMediaPlaybackSuspended(false) {
                    let js = "document.querySelectorAll('[data-was-playing=\"true\"]')"
                        + ".forEach(e=>{e.play();delete e.dataset.wasPlaying})"
                    webView.evaluateJavaScript(js)
                }
            }
        }

        observers = [willResign, didBackground]
    }

    private static func stop() {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        observers = []
    }
}
