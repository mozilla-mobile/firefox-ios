// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0

import UIKit

class ThemedNavigationController: DismissableNavigationViewController {
    var presentingModalViewControllerDelegate: PresentingModalViewControllerDelegate?
    
    @objc func done() {
        if let delegate = presentingModalViewControllerDelegate {
            delegate.dismissPresentedModalViewController(self, animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return topViewController?.preferredStatusBarStyle ?? LegacyThemeManager.instance.statusBarStyle
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        modalPresentationStyle = .overFullScreen
        modalPresentationCapturesStatusBarAppearance = true
        
        applyTheme()

        NotificationCenter.default.addObserver(self, selector: #selector(themeChanged), name: .DisplayThemeChanged, object: nil)
    }

    @objc func themeChanged() {
        applyTheme()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard let profile = (UIApplication.shared.delegate as? AppDelegate)?.profile else { return }

        let shouldStayDark = LegacyThemeManager.instance.current.isDark && NightModeHelper.isActivated(profile.prefs)
        LegacyThemeManager.instance.themeChanged(from: previousTraitCollection, to: traitCollection, forceDark: shouldStayDark)
    }
}

extension ThemedNavigationController: NotificationThemeable {
    private func setupNavigationBarAppearance() {
        let standardAppearance = UINavigationBarAppearance()
            standardAppearance.configureWithOpaqueBackground()
            standardAppearance.backgroundColor = UIColor.theme.tableView.headerBackground
            standardAppearance.titleTextAttributes = [.foregroundColor: UIColor.theme.ecosia.navigationBarText]
            standardAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.theme.ecosia.navigationBarText]
            standardAppearance.shadowImage = .init()
            standardAppearance.shadowColor = nil
        navigationBar.standardAppearance = standardAppearance
        navigationBar.compactAppearance = standardAppearance
        navigationBar.scrollEdgeAppearance = standardAppearance
        
        // Ecosia
        navigationBar.prefersLargeTitles = true
        
        if #available(iOS 15.0, *) {
            navigationBar.compactScrollEdgeAppearance = standardAppearance
        }
        navigationBar.tintColor = UIColor.theme.general.controlTint
    }
    
    func applyTheme() {
        setupNavigationBarAppearance()
        setNeedsStatusBarAppearanceUpdate()
        viewControllers.forEach {
            ($0 as? NotificationThemeable)?.applyTheme()
        }

        navigationBar.setNeedsDisplay()
        setNeedsStatusBarAppearanceUpdate()
        navigationBar.tintColor = UIColor.theme.general.controlTint
    }
}

protocol PresentingModalViewControllerDelegate: AnyObject {
    func dismissPresentedModalViewController(_ modalViewController: UIViewController, animated: Bool)
}

class ModalSettingsNavigationController: UINavigationController {
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
}
