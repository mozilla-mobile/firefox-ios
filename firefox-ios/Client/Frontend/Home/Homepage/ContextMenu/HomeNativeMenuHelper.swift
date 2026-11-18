// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import Storage

@MainActor
final class HomeNativeMenuHelper {
    private typealias A11y = AccessibilityIdentifiers.FirefoxHomepage.TopSites.ContextMenu

    private let windowUUID: WindowUUID
    private let toastContainer: UIView

    init(windowUUID: WindowUUID, toastContainer: UIView) {
        self.windowUUID = windowUUID
        self.toastContainer = toastContainer
    }

    func menu(for item: HomepageItem, sourceView: UIView?) -> UIMenu? {
        let items = menuItems(for: item, sourceView: sourceView)
        return items.isEmpty ? nil : UIMenu(children: items)
    }

    private func menuItems(for item: HomepageItem, sourceView: UIView?) -> [UIMenuElement] {
        switch item {
        case .topSite(let config, _):
            return getTopSitesActions(for: config, sourceView: sourceView)
        default:
            return []
        }
    }

    // MARK: - Top sites

    private func getTopSitesActions(for item: TopSiteConfiguration, sourceView: UIView?) -> [UIMenuElement] {
        let site = item.site
        guard let siteURL = site.url.asURL else { return [] }

        switch site.type {
        case .pinnedSite:
            return [
                getUnpinTopSiteAction(site: site),
                getOpenInNewTabAction(url: siteURL),
                getOpenInPrivateTabAction(url: siteURL, menuType: .topSite),
                getRemoveTopSiteAction(site: site),
                getShareAction(url: siteURL, sourceView: sourceView)
            ]
        case .sponsoredSite:
            return [
                getOpenInNewTabAction(url: siteURL),
                getOpenInPrivateTabAction(url: siteURL, menuType: .topSite),
                getTopSitesSettingsAction(),
                getSponsoredContentAction(),
                getShareAction(url: siteURL, sourceView: sourceView)
            ]
        default:
            return [
                getPinTopSiteAction(site: site),
                getOpenInNewTabAction(url: siteURL),
                getOpenInPrivateTabAction(url: siteURL, menuType: .topSite),
                getRemoveTopSiteAction(site: site),
                getShareAction(url: siteURL, sourceView: sourceView)
            ]
        }
    }

    private func getPinTopSiteAction(site: Site) -> UIAction {
        let action = UIAction(
            title: .PinTopsiteActionTitle2,
            image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.pin)
        ) { [windowUUID] _ in
            store.dispatch(ContextMenuAction(site: site,
                                             windowUUID: windowUUID,
                                             actionType: ContextMenuActionType.tappedOnPinTopSite))
        }
        action.accessibilityIdentifier = A11y.pin
        return action
    }

    private func getUnpinTopSiteAction(site: Site) -> UIAction {
        let action = UIAction(
            title: .UnpinTopsiteActionTitle2,
            image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.pinSlash)
        ) { [windowUUID] _ in
            store.dispatch(ContextMenuAction(site: site,
                                             windowUUID: windowUUID,
                                             actionType: ContextMenuActionType.tappedOnUnpinTopSite))
        }
        action.accessibilityIdentifier = A11y.unpin
        return action
    }

    private func getRemoveTopSiteAction(site: Site) -> UIAction {
        let action = UIAction(
            title: .RemoveContextMenuTitle,
            image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.cross),
            attributes: .destructive
        ) { [windowUUID] _ in
            store.dispatch(ContextMenuAction(site: site,
                                             windowUUID: windowUUID,
                                             actionType: ContextMenuActionType.tappedOnRemoveTopSite))
        }
        action.accessibilityIdentifier = A11y.remove
        return action
    }

    private func getTopSitesSettingsAction() -> UIAction {
        let action = UIAction(
            title: .FirefoxHomepage.ContextualMenu.Settings,
            image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.settings)
        ) { [windowUUID] _ in
            store.dispatch(NavigationBrowserAction(
                navigationDestination: NavigationDestination(.settings(.topSites)),
                windowUUID: windowUUID,
                actionType: NavigationBrowserActionType.tapOnSettingsSection))
            store.dispatch(ContextMenuAction(windowUUID: windowUUID,
                                             actionType: ContextMenuActionType.tappedOnSettingsAction))
        }
        action.accessibilityIdentifier = A11y.settings
        return action
    }

    private func getSponsoredContentAction() -> UIAction {
        let action = UIAction(
            title: .FirefoxHomepage.ContextualMenu.SponsoredContent,
            image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.helpCircle)
        ) { [windowUUID] _ in
            guard let url = SupportUtils.URLForTopic("sponsor-privacy") else { return }
            store.dispatch(NavigationBrowserAction(
                navigationDestination: NavigationDestination(.newTab,
                                                             url: url,
                                                             isPrivate: false,
                                                             selectNewTab: true),
                windowUUID: windowUUID,
                actionType: NavigationBrowserActionType.tapOnOpenInNewTab))
            store.dispatch(ContextMenuAction(windowUUID: windowUUID,
                                             actionType: ContextMenuActionType.tappedOnSponsoredAction))
        }
        action.accessibilityIdentifier = A11y.sponsoredContent
        return action
    }

    private func getOpenInNewTabAction(url: URL) -> UIAction {
        let action = UIAction(
            title: .OpenInNewTabContextMenuTitle,
            image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.plus)
        ) { [windowUUID] _ in
            store.dispatch(NavigationBrowserAction(
                navigationDestination: NavigationDestination(.newTab,
                                                             url: url,
                                                             isPrivate: false,
                                                             selectNewTab: false),
                windowUUID: windowUUID,
                actionType: NavigationBrowserActionType.tapOnOpenInNewTab))
        }
        action.accessibilityIdentifier = A11y.openInNewTab
        return action
    }

    private func getOpenInPrivateTabAction(url: URL, menuType: MenuType) -> UIAction {
        let action = UIAction(
            title: .OpenInNewPrivateTabContextMenuTitle,
            image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.privateMode)
        ) { [windowUUID] _ in
            store.dispatch(NavigationBrowserAction(
                navigationDestination: NavigationDestination(.newTab,
                                                             url: url,
                                                             isPrivate: true,
                                                             selectNewTab: false),
                windowUUID: windowUUID,
                actionType: NavigationBrowserActionType.tapOnOpenInNewTab))
            store.dispatch(ContextMenuAction(menuType: menuType,
                                             windowUUID: windowUUID,
                                             actionType: ContextMenuActionType.tappedOnOpenNewPrivateTab))
        }
        action.accessibilityIdentifier = A11y.openInPrivateTab
        return action
    }

    private func getShareAction(url: URL, sourceView: UIView?) -> UIAction {
        let action = UIAction(
            title: .ShareContextMenuTitle,
            image: UIImage.templateImageNamed(StandardImageIdentifiers.Large.shareApple)
        ) { [windowUUID, toastContainer] _ in
            let config = ShareSheetConfiguration(shareType: .site(url: url),
                                                 shareMessage: nil,
                                                 sourceView: sourceView ?? UIView(),
                                                 sourceRect: nil,
                                                 toastContainer: toastContainer,
                                                 popoverArrowDirection: [.up, .down, .left])
            store.dispatch(NavigationBrowserAction(
                navigationDestination: NavigationDestination(.shareSheet(config)),
                windowUUID: windowUUID,
                actionType: NavigationBrowserActionType.tapOnShareSheet))
        }
        action.accessibilityIdentifier = A11y.share
        return action
    }
}
