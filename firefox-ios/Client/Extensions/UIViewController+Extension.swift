// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Shared
import Common

enum NavigationItemLocation {
    case Left
    case Right
}

enum NavigationItemText {
    case Done
    case Close

    func localizedString() -> String {
        switch self {
        case .Done:
            return .SettingsSearchDoneButton
        case .Close:
            return .CloseButtonTitle
        }
    }
}

struct ViewControllerConsts {
    struct PreferredSize {
        static let IntroViewController = CGSize(width: 570, height: 755)
        static let UpdateViewController = CGSize(width: 375, height: 667)
        static let DBOnboardingViewController = CGSize(width: 624, height: 680)
    }
}

extension UIViewController {
    /// Determines whether, based on size class, the particular view controller should
    /// use iPad setup, as defined by design requirements. All iPad devices use a
    /// combination of either (.compact, .regular) or (.regular, .regular) size class
    /// for (width, height) for both fullscreen AND multi-tasking layouts. In some
    /// instances, we may wish to use iPhone layouts on the iPad when its size class
    /// is of type (.compact, .regular).
    func shouldUseiPadSetup(traitCollection: UITraitCollection? = nil) -> Bool {
        let trait = traitCollection == nil ? self.traitCollection : traitCollection
        if UIDevice.current.userInterfaceIdiom == .pad {
            return trait!.horizontalSizeClass != .compact
        }

        return false
    }

    /// This presents a View Controller with a bar button item that can be used to dismiss the VC
    /// - Parameters:
    ///     - navItemLocation: Define whether dismiss bar button item should be on the right
    ///                        or left of the navigation bar
    ///     - navItemText: Define whether bar button item text should be "Done" or "Close"
    ///     - vcBeingPresented: ViewController to present with this bar button item
    ///     - topTabsVisible: If tabs of browser should still be visible. iPad only.
    func presentThemedViewController(
        navItemLocation: NavigationItemLocation,
        navItemText: NavigationItemText,
        vcBeingPresented: UIViewController,
        topTabsVisible: Bool
    ) {
        guard let uuid = (view as ThemeUUIDIdentifiable).currentWindowUUID else { return }

        let vcToPresent = vcBeingPresented
        let buttonItem = UIBarButtonItem(title: navItemText.localizedString(), style: .plain) { [weak self] _ in
            // Note: Do not initialize the back button action with an @objc selector, as `dismissVC`'s method signature
            // no longer matches (will crash).
            self?.dismissVC()
        }
        switch navItemLocation {
        case .Left:
            vcToPresent.navigationItem.leftBarButtonItem = buttonItem
        case .Right:
            vcToPresent.navigationItem.rightBarButtonItem = buttonItem
        }
        let themedNavigationController = ThemedNavigationController(rootViewController: vcToPresent,
                                                                    windowUUID: uuid)
        themedNavigationController.navigationBar.isTranslucent = false
        if topTabsVisible {
            themedNavigationController.preferredContentSize = CGSize(
                width: ViewControllerConsts.PreferredSize.IntroViewController.width,
                height: ViewControllerConsts.PreferredSize.IntroViewController.height)
            themedNavigationController.modalPresentationStyle = .formSheet
        } else {
            themedNavigationController.modalPresentationStyle = .fullScreen
        }
        presentWithModalDismissIfNeeded(themedNavigationController, animated: true)
    }

    func dismissVC(withCompletion completion: (() -> Void)? = nil) {
        self.dismiss(animated: true, completion: completion)
    }

    /// A convenience function to dismiss modal presentation views if they are
    /// currently presented.
    func presentWithModalDismissIfNeeded(_ viewController: UIViewController, animated: Bool) {
        if let presentedViewController = presentedViewController {
            presentedViewController.dismiss(animated: false, completion: {
                self.present(viewController, animated: animated, completion: nil)
            })
        } else {
            present(viewController, animated: animated, completion: nil)
        }
    }

    /// Returns the `SceneDelegate` that's foregrounded, active and currently engaged with.
    var sceneForVC: SceneDelegate? {
        guard let scene = walkChainUntil(visiting: UIWindow.self)?
            .windowScene?
            .delegate as? SceneDelegate
        else { return nil }

        return scene
    }

    // MARK: - Logger Swizzling

    /// Ignore some view controller out of logs to avoid spamming the logger,
    /// which would reduce the usefulness of logging view controllers
    private enum LoggerIgnoreViewController: String, CaseIterable {
        case compatibility = "UICompatibilityInputViewController"
        case defaultTheme = "ThemedDefaultNavigationController"
        case dismissable = "DismissableNavigationViewController"
        case editingOverlay = "UIEditingOverlayViewController"
        case inputWindow = "UIInputWindowController"
        case themed = "ThemedNavigationController"
        case screenTime = "STWebpageController"
        case remoteScreenTime = "STWebRemoteViewController"
    }

    /// Add a swizzle on top of the viewWillAppear function to log whenever a view controller will appear.
    /// Needs to be only called once on app launch.
    static func loggerSwizzle() {
        let originalSelector = #selector(UIViewController.viewWillAppear(_:))
        let swizzledSelector = #selector(UIViewController.loggerViewWillAppear(_:))

        guard let originalMethod = class_getInstanceMethod(self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(self, swizzledSelector) else { return }

        method_exchangeImplementations(originalMethod, swizzledMethod)
    }

    @objc
    private func loggerViewWillAppear(_ animated: Bool) {
        let values: [String] = LoggerIgnoreViewController.allCases.map { $0.rawValue }
        if !values.contains("\(type(of: self))") {
            DefaultLogger.shared.log("\(type(of: self)) will appear", level: .info, category: .lifecycle)
        }

        loggerViewWillAppear(animated)
    }
}
