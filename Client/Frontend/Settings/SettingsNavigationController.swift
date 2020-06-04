/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit

protocol PopoverPresenterDataProviderDelegate {
    var view: UIView! { get }
    var popoverPresentationTapLocation: CGPoint { get }
}

class ThemedNavigationController: UINavigationController {
    var presentingModalViewControllerDelegate: PresentingModalViewControllerDelegate?

    @objc func done() {
        if let delegate = presentingModalViewControllerDelegate {
            delegate.dismissPresentedModalViewController(self, animated: true)
        } else {
            self.dismiss(animated: true, completion: nil)
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return ThemeManager.instance.statusBarStyle
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        modalPresentationStyle = .formSheet
        modalPresentationCapturesStatusBarAppearance = true
        applyTheme()
    }

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        if #available(iOS 13, *), viewControllerToPresent is UIDocumentMenuViewController && UIDevice.current.userInterfaceIdiom == .phone {
          viewControllerToPresent.popoverPresentationController?.delegate = self
        }
        super.present(viewControllerToPresent, animated: flag, completion: completion)
    }
}


extension ThemedNavigationController: UIPopoverPresentationControllerDelegate {

    func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
        if (popoverPresentationController.presentationStyle == .popover &&
            (popoverPresentationController.sourceView == nil || popoverPresentationController.sourceRect == .zero)) {
            if let dataProviderController = viewControllers.last as? PopoverPresenterDataProviderDelegate {
                popoverPresentationController.sourceView = dataProviderController.view
                popoverPresentationController.sourceRect = CGRect(origin: dataProviderController.popoverPresentationTapLocation, size: CGSize(width: 40, height: 40))
            } else {
                popoverPresentationController.sourceView = view
                popoverPresentationController.sourceRect = CGRect(x: view.center.x, y: view.center.y, width: 40, height: 40)
            }
        }
    }
}


extension ThemedNavigationController: Themeable {
    func applyTheme() {
        navigationBar.barTintColor = UIColor.theme.tableView.headerBackground
        navigationBar.tintColor = UIColor.theme.general.controlTint
        navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.theme.tableView.headerTextDark]
        setNeedsStatusBarAppearanceUpdate()
        viewControllers.forEach {
            ($0 as? Themeable)?.applyTheme()
        }
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
