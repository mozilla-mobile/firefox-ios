// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit

struct WebMenuAction {
    var openInDefaultBrowser: (URL) -> Void
    var showCopy: (URL) -> Void
    var showSharePage: (OpenUtils, UIView, UIViewController) -> Void
    var openLink: (URL) -> Void
}

extension WebMenuAction {
    func openInDefaultBrowserItem(for url: URL) -> MenuAction {
        MenuAction(title: UIConstants.strings.shareOpenInDefaultBrowser, image: "icon_favicon") {
            self.openInDefaultBrowser(url)
        }
    }

    func sharePageItem(for utils: OpenUtils, sender: UIView, presenter: UIViewController) -> MenuAction {
        MenuAction(title: UIConstants.strings.sharePage, image: "icon_openwith_active") {
            self.showSharePage(utils, sender, presenter)
        }
    }

    func copyItem(url: URL) -> MenuAction {
        MenuAction(title: UIConstants.strings.copyAddress, image: "icon_link") {
            self.showCopy(url)
        }
    }

    func openLink(url: URL) -> MenuAction {
        MenuAction(title: UIConstants.strings.shareOpenLink, image: nil) {
            self.openLink(url)
        }
    }
}

extension WebMenuAction {
    static let live = WebMenuAction(openInDefaultBrowser: { url in
        UIApplication.shared.open(url, options: [:])

    }, showCopy: { url in
        UIPasteboard.general.string = url.absoluteString
        Toast(text: UIConstants.strings.copyURLToast).show()
    }, showSharePage: { utils, sender, presenter in
        let shareVC = utils.buildShareViewController()

        // Exact frame dimensions taken from presentPhotonActionSheet
        shareVC.popoverPresentationController?.sourceView = sender
        shareVC.popoverPresentationController?.sourceRect =
        CGRect(
            x: sender.frame.width/2,
            y: sender.frame.size.height,
            width: 1,
            height: 1
        )

        shareVC.becomeFirstResponder()
        presenter.present(shareVC, animated: true, completion: nil)
    }, openLink: { url in })
}
