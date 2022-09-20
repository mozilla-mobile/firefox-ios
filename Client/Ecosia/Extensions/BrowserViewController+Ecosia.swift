/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import UIKit
import Core
import Shared

extension BrowserViewController: HomepageViewControllerDelegate {
    // for iPhone we hide the whole header, for iPad only the urlbar
    var scrollOverlays: [UIView] {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return [urlBar.locationContainer, urlBar.searchIconImageView]
        } else {
            return [header]
        }
    }

    func home(_ home: HomepageViewController, didScroll searchPos: CGFloat, offset: CGFloat) {

        guard !urlBar.inOverlayMode,
              (urlBar.currentURL.flatMap({ InternalURL($0)?.isAboutHomeURL }) ?? false || urlBar.currentURL == nil)
        else {
            scrollOverlays.forEach { $0.alpha = 1 }
            if view.traitCollection.userInterfaceIdiom == .phone {
                statusBarOverlay.backgroundColor = .theme.textField.background
            }
            return
        }
        let alpha: CGFloat = searchPos <= offset ? 1 : 0
        scrollOverlays.forEach { $0.alpha = alpha }

        if view.traitCollection.userInterfaceIdiom == .phone {
            statusBarOverlay.backgroundColor = alpha > 0  ? .theme.textField.background : .theme.ecosia.ntpBackground
        }
    }

    func homeDidTapSearchButton(_ home: HomepageViewController) {
        urlBar.tabLocationViewDidTapLocation(self.urlBar.locationView)
    }

    func home(_ home: HomepageViewController, willBegin drag: CGPoint) {
        guard urlBar.inOverlayMode else { return }
        urlBar.leaveOverlayMode(didCancel: true)
    }

    func homeDidPressPersonalCounter(_ home: HomepageViewController, completion: (() -> Void)? = nil) {
        presentEcosiaWorld(completion)
    }

    func presentEcosiaWorld(_ completion: (() -> Void)? = nil) {
        ecosiaNavigation.popToRootViewController(animated: false)
        present(ecosiaNavigation, animated: true, completion: completion)
    }
}

extension BrowserViewController: EcosiaHomeDelegate {
    func ecosiaHome(didSelectURL url: URL) {
        guard let tab = tabManager.selectedTab else { return }
        finishEditingAndSubmit(url, visitType: .link, forTab: tab)
    }
}

extension BrowserViewController: DefaultBrowserDelegate {
    @available(iOS 14, *)
    func defaultBrowserDidShow(_ defaultBrowser: DefaultBrowser) {
        User.shared.firstTime = false
        homepageViewController?.reloadTooltip()
    }
}
