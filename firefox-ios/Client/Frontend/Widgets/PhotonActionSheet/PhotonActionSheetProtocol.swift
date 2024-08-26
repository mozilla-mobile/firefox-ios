// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared
import Storage
import UIKit

protocol PhotonActionSheetProtocol {
    var tabManager: TabManager { get }
    var profile: Profile { get }
    var themeManager: ThemeManager { get }
}

extension PhotonActionSheetProtocol {
    typealias PresentableVC = UIViewController & UIPopoverPresentationControllerDelegate

    func presentSheetWith(viewModel: PhotonActionSheetViewModel,
                          on viewController: PresentableVC,
                          from view: UIView) {
        // TODO: Regression testing needed here.
        guard let uuid = view.currentWindowUUID else { return }

        let sheet = PhotonActionSheet(viewModel: viewModel, windowUUID: uuid)
        sheet.modalPresentationStyle = viewModel.modalStyle
        sheet.photonTransitionDelegate = PhotonActionSheetAnimator()

        if let popoverVC = sheet.popoverPresentationController, sheet.modalPresentationStyle == .popover {
            popoverVC.delegate = viewController
            popoverVC.sourceView = view
            popoverVC.sourceRect = view.bounds

            let trait = viewController.traitCollection
            if viewModel.isMainMenu {
                let margins = viewModel.getMainMenuPopOverMargins(
                    trait: trait,
                    view: view,
                    presentedOn: viewController
                )
                popoverVC.popoverLayoutMargins = margins
            }
            popoverVC.permittedArrowDirections = viewModel.getPossibleArrowDirections(trait: trait)
        }
        viewController.present(sheet, animated: true, completion: nil)
    }

    func getLongPressLocationBarActions(with view: UIView, alertContainer: UIView) -> [PhotonRowActions] {
        let pasteGoAction = SingleActionViewModel(title: .PasteAndGoTitle,
                                                  iconString: StandardImageIdentifiers.Large.clipboard) { _ in
            if let pasteboardContents = UIPasteboard.general.string {
                if let urlBar = view as? URLBarView {
                    urlBar.delegate?.urlBar(urlBar, didSubmitText: pasteboardContents)
                } else if let toolbar = view as? AddressToolbarContainer {
                    toolbar.delegate?.openBrowser(searchTerm: pasteboardContents)
                }
            }
        }
        pasteGoAction.accessibilityId = AccessibilityIdentifiers.Photon.pasteAndGoAction

        let pasteAction = SingleActionViewModel(title: .PasteTitle,
                                                iconString: StandardImageIdentifiers.Large.clipboard) { _ in
            if let pasteboardContents = UIPasteboard.general.string {
                if let urlBar = view as? URLBarView {
                    urlBar.enterOverlayMode(pasteboardContents, pasted: true, search: true)
                } else if let toolbar = view as? AddressToolbarContainer {
                    toolbar.enterOverlayMode(pasteboardContents, pasted: true, search: true)
                }
            }
        }
        pasteAction.accessibilityId = AccessibilityIdentifiers.Photon.pasteAction

        let copyAddressAction = SingleActionViewModel(title: .CopyAddressTitle,
                                                      iconString: StandardImageIdentifiers.Large.link) { _ in
            let currentURL = tabManager.selectedTab?.currentURL()
            if let url = tabManager.selectedTab?.canonicalURL?.displayURL ?? currentURL {
                UIPasteboard.general.url = url
                SimpleToast().showAlertWithText(.LegacyAppMenu.AppMenuCopyURLConfirmMessage,
                                                bottomContainer: alertContainer,
                                                theme: themeManager.getCurrentTheme(for: tabManager.windowUUID))
            }
        }

        if UIPasteboard.general.hasStrings {
            return [pasteGoAction.items, pasteAction.items, copyAddressAction.items]
        } else {
            return [copyAddressAction.items]
        }
    }

    func getRefreshLongPressMenu(for tab: Tab) -> [PhotonRowActions] {
        guard tab.webView?.url != nil
                && (tab.getContentScript(name: ReaderMode.name()) as? ReaderMode)?.state != .active
        else { return [] }

        let defaultUAisDesktop = UserAgent.isDesktop(ua: UserAgent.getUserAgent())
        let toggleActionTitle: String
        // swiftlint:disable line_length
        if defaultUAisDesktop {
            toggleActionTitle = tab.changedUserAgent ? .LegacyAppMenu.AppMenuViewDesktopSiteTitleString : .LegacyAppMenu.AppMenuViewMobileSiteTitleString
        } else {
            toggleActionTitle = tab.changedUserAgent ? .LegacyAppMenu.AppMenuViewMobileSiteTitleString : .LegacyAppMenu.AppMenuViewDesktopSiteTitleString
        }
        // swiftlint:enable line_length
        let toggleDesktopSite = SingleActionViewModel(title: toggleActionTitle,
                                                      iconString: StandardImageIdentifiers.Large.deviceDesktop) { _ in
            if let url = tab.url {
                tab.toggleChangeUserAgent()
                Tab.ChangeUserAgent.updateDomainList(
                    forUrl: url,
                    isChangedUA: tab.changedUserAgent,
                    isPrivate: tab.isPrivate
                )
            }
        }.items

        if let url = tab.webView?.url,
           let helper = tab.contentBlocker,
           helper.isEnabled,
           helper.blockingStrengthPref == .strict {
            let isSafelisted = helper.status == .safelisted

            let title: String = !isSafelisted ? .TrackingProtectionReloadWithout : .TrackingProtectionReloadWith
            let imageIdentifiers = StandardImageIdentifiers.Large.self
            let imageName = helper.isEnabled ? imageIdentifiers.shieldSlash : imageIdentifiers.shield
            let toggleTP = SingleActionViewModel(title: title, iconString: imageName) { _ in
                ContentBlocker.shared.safelist(enable: !isSafelisted, url: url) {
                    tab.reload()
                }
            }.items
            return [toggleDesktopSite, toggleTP]
        } else {
            return [toggleDesktopSite]
        }
    }
}
