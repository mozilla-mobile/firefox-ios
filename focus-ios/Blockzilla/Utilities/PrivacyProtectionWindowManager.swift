/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

/// Covers app content with a splash overlay while Focus is backgrounded, so the
/// app-switcher snapshot can't capture the live page (FXIOS-16007).
///
/// The window is built once and kept alive. Rebuilding it on each resign raced the
/// snapshot — the fresh window hadn't rendered yet. Reusing it makes `show()` a
/// synchronous reveal.
final class PrivacyProtectionWindowManager {
    // Injected so tests can supply a plain UIWindow; a UIWindowScene can't be built
    // in a unit test. Returns nil when no scene is available yet.
    private let privacyWindowFactory: () -> UIWindow?
    private let mainWindowProvider: () -> UIWindow?
    private let rootViewControllerFactory: () -> UIViewController

    private(set) var privacyWindow: UIWindow?

    init(
        privacyWindowFactory: @escaping () -> UIWindow?,
        mainWindowProvider: @escaping () -> UIWindow?,
        rootViewControllerFactory: @escaping () -> UIViewController
    ) {
        self.privacyWindowFactory = privacyWindowFactory
        self.mainWindowProvider = mainWindowProvider
        self.rootViewControllerFactory = rootViewControllerFactory
    }

    func show() {
        if privacyWindow == nil {
            guard let window = privacyWindowFactory() else { return }
            window.rootViewController = rootViewControllerFactory()
            window.windowLevel = .alert + 1
            privacyWindow = window
        }
        privacyWindow?.makeKeyAndVisible()
    }

    func hide() {
        privacyWindow?.isHidden = true
        mainWindowProvider()?.makeKeyAndVisible()
    }
}
