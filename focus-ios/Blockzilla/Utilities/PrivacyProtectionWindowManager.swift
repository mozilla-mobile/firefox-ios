/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

/// Splash overlay shown over app content while Focus is backgrounded, so the
/// app-switcher snapshot can't capture the live page (FXIOS-16007).
///
/// The overlay window is built once and reused; rebuilding it on each resign raced
/// the snapshot, so it stays alive and `show()` just reveals it.
final class PrivacyProtectionWindowManager {
    // Injected so tests can supply a plain UIWindow (a UIWindowScene can't be built in a unit test).
    private let privacyWindowFactory: () -> UIWindow?
    private let rootViewControllerFactory: () -> UIViewController

    private(set) var privacyWindow: UIWindow?

    init(
        privacyWindowFactory: @escaping () -> UIWindow?,
        rootViewControllerFactory: @escaping () -> UIViewController
    ) {
        self.privacyWindowFactory = privacyWindowFactory
        self.rootViewControllerFactory = rootViewControllerFactory
    }

    func show() {
        if privacyWindow == nil {
            guard let window = privacyWindowFactory() else { return }
            window.rootViewController = rootViewControllerFactory()
            window.windowLevel = .alert + 1
            privacyWindow = window
        }
        // Reveal without making the overlay key. The app also resigns active while a
        // Face ID prompt is up, and taking key status away from the main window ends
        // the text input session on the web view, so a password picked from the
        // QuickType bar arrived with nothing left to fill (FXIOS-17309). The splash
        // button still receives touches on a non-key window.
        privacyWindow?.isHidden = false
    }

    func hide() {
        privacyWindow?.isHidden = true
    }
}
