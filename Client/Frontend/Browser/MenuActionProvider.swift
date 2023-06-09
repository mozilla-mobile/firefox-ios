// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared

protocol MenuActionProvider {
    func getNewTabAction() -> PhotonRowActions?
    func getHistoryLibraryAction() -> PhotonRowActions
    func getDownloadsLibraryAction() -> PhotonRowActions

    func getZoomAction() -> PhotonRowActions?
    func getFindInPageAction() -> PhotonRowActions
    func getRequestDesktopSiteAction() -> PhotonRowActions?
    func getCopyAction() -> PhotonRowActions?
}

protocol MenuActionable {
    var profile: Profile { get }
    var delegate: ToolBarActionMenuDelegate? { get }
    var selectedTab: Tab? { get }

    func newTabAction()
    func historyLibraryAction()
    func downloadsLibraryAction()
    func zoomAction()
    func findInPageAction()
    func requestDesktopSiteAction()
    func copyAction()
}

extension MenuActionable {
    func newTabAction() {
        guard let tab = selectedTab else { return }
        let shouldFocusLocationField = NewTabAccessors.getNewTabPage(self.profile.prefs) != .homePage
        self.delegate?.openNewTabFromMenu(focusLocationField: shouldFocusLocationField, isPrivate: tab.isPrivate)
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .createNewTab)
    }

    func historyLibraryAction() {
        self.delegate?.showLibrary(panel: .history)
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .viewHistoryPanel)
    }

    func downloadsLibraryAction() {
        self.delegate?.showLibrary(panel: .downloads)
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .viewDownloadsPanel)
    }

    func zoomAction() {
        guard let tab = selectedTab else { return }
        self.delegate?.showZoomPage(tab: tab)
    }

    func findInPageAction() {
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .findInPage)
        self.delegate?.showFindInPage()
    }

    func requestDesktopSiteAction() {
        guard let tab = selectedTab else { return }

        let defaultUAisDesktop = UserAgent.isDesktop(ua: UserAgent.getUserAgent())
        let siteTypeTelemetryObject: TelemetryWrapper.EventObject
        if defaultUAisDesktop {
            siteTypeTelemetryObject = .requestDesktopSite
        } else {
            siteTypeTelemetryObject = .requestMobileSite
        }

        if let url = tab.url {
            tab.toggleChangeUserAgent()
            Tab.ChangeUserAgent.updateDomainList(forUrl: url, isChangedUA: tab.changedUserAgent, isPrivate: tab.isPrivate)
            TelemetryWrapper.recordEvent(category: .action, method: .tap, object: siteTypeTelemetryObject)
        }
    }

    func copyAction() {
        TelemetryWrapper.recordEvent(category: .action, method: .tap, object: .copyAddress)
        if let url = self.selectedTab?.canonicalURL?.displayURL {
            UIPasteboard.general.url = url
            self.delegate?.showToast(message: .AppMenu.AppMenuCopyURLConfirmMessage, toastAction: .copyUrl, url: nil)
        }
    }
}

extension MenuActionProvider where Self: MenuActionable {
    // MARK: - Actions

    func getNewTabAction() -> PhotonRowActions? {
        guard selectedTab != nil else { return nil }
        return SingleActionViewModel(title: .AppMenu.NewTab,
                                     iconString: ImageIdentifiers.newTab) { _ in
            self.newTabAction()
        }.items
    }

    func getHistoryLibraryAction() -> PhotonRowActions {
        return SingleActionViewModel(title: .AppMenu.AppMenuHistory,
                                     iconString: ImageIdentifiers.history) { _ in
            self.historyLibraryAction()
        }.items
    }

    func getDownloadsLibraryAction() -> PhotonRowActions {
        return SingleActionViewModel(title: .AppMenu.AppMenuDownloads,
                                     iconString: ImageIdentifiers.downloads) { _ in
            self.downloadsLibraryAction()
        }.items
    }

    // MARK: Zoom

    func getZoomAction() -> PhotonRowActions? {
        guard let tab = selectedTab else { return nil }
        let zoomLevel = NumberFormatter.localizedString(from: NSNumber(value: tab.pageZoom), number: .percent)
        let title = String(format: .AppMenu.ZoomPageTitle, zoomLevel)
        return SingleActionViewModel(title: title,
                                     iconString: ImageIdentifiers.zoomIn) { _ in
            self.zoomAction()
        }.items
    }

    func getFindInPageAction() -> PhotonRowActions {
        return SingleActionViewModel(title: .AppMenu.AppMenuFindInPageTitleString,
                                     iconString: ImageIdentifiers.findInPage) { _ in
            self.findInPageAction()
        }.items
    }

    func getRequestDesktopSiteAction() -> PhotonRowActions? {
        guard let tab = selectedTab else { return nil }
        let defaultUAisDesktop = UserAgent.isDesktop(ua: UserAgent.getUserAgent())
        let toggleActionTitle: String
        let toggleActionIcon: String
        if defaultUAisDesktop {
            toggleActionTitle = tab.changedUserAgent ? .AppMenu.AppMenuViewDesktopSiteTitleString : .AppMenu.AppMenuViewMobileSiteTitleString
            toggleActionIcon = tab.changedUserAgent ? ImageIdentifiers.requestDesktopSite : ImageIdentifiers.requestMobileSite
        } else {
            toggleActionTitle = tab.changedUserAgent ? .AppMenu.AppMenuViewMobileSiteTitleString : .AppMenu.AppMenuViewDesktopSiteTitleString
            toggleActionIcon = tab.changedUserAgent ? ImageIdentifiers.requestMobileSite : ImageIdentifiers.requestDesktopSite
        }
        return SingleActionViewModel(title: toggleActionTitle,
                                     iconString: toggleActionIcon) { _ in
            self.requestDesktopSiteAction()
        }.items
    }

    func getCopyAction() -> PhotonRowActions? {
        return SingleActionViewModel(title: .AppMenu.AppMenuCopyLinkTitleString,
                                     iconString: ImageIdentifiers.copyLink) { _ in
            self.copyAction()
        }.items
    }
}
