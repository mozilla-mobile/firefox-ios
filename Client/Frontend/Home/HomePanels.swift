/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import Foundation
import UIKit
import Shared

/**
 * Data for identifying and constructing a HomePanel.
 */
struct HomePanelDescriptor: CustomStringConvertible {
    let className: String
    let makeViewController: PanelGenerator
    let imageName: String
    let accessibilityLabel: String

    var description: String {
        return "{ \(accessibilityLabel) }"
    }

    init(className: String, imageName: String, accessibilityLabel: String) {
        self.className = className
        self.imageName = imageName
        self.accessibilityLabel = accessibilityLabel
        makeViewController = { panelForClassName(className, withProfile: $0)! }
    }

    init(json: JSON) {
        let _className = json["className"].asString!
        imageName = json["imageName"].asString!
        accessibilityLabel = json["accessibilityLabel"].asString!
        makeViewController = { panelForClassName(_className, withProfile: $0)! }
        className = _className
    }

    func jsonStringify() -> String {
        let jsonDict = [
            "className": className,
            "imageName": imageName,
            "accessibilityLabel": accessibilityLabel
        ]
        return JSON.stringify(jsonDict)
    }
}

typealias PanelGenerator = (profile: Profile) -> UIViewController

private enum SupportedPanels: String {
    case TopSitesPanel = "TopSitesPanel"
    case BookmarksPanel = "BookmarksPanel"
    case HistoryPanel = "HistoryPanel"
    case RemoteTabsPanel = "RemoteTabsPanel"
    case ReadingListPanel = "ReadingListPanel"
}

private func panelForClassName(className: String, withProfile profile: Profile) -> UIViewController? {
    if let panel = SupportedPanels(rawValue: className) {
        switch panel {
        case .TopSitesPanel:
            let vc = TopSitesPanel(profile: profile)
            return vc
        case .BookmarksPanel:
            let vc = BookmarksPanel()
            vc.profile = profile
            return vc
        case .HistoryPanel:
            let vc = HistoryPanel()
            vc.profile = profile
            return vc
        case .RemoteTabsPanel:
            let vc = RemoteTabsPanel()
            vc.profile = profile
            return vc
        case .ReadingListPanel:
            let vc = ReadingListPanel()
            vc.profile = profile
            return vc
        }
    } else {
        // Unsupported panel!
        return nil
    }
}

private var defaultPanels: [HomePanelDescriptor] = [
    HomePanelDescriptor(
        className: "TopSitesPanel",
        imageName: "TopSites",
        accessibilityLabel: NSLocalizedString("Top sites", comment: "Panel accessibility label")
    ),

    HomePanelDescriptor(
        className: "BookmarksPanel",
        imageName: "Bookmarks",
        accessibilityLabel: NSLocalizedString("Bookmarks", comment: "Panel accessibility label")
    ),

    HomePanelDescriptor(
        className: "HistoryPanel",
        imageName: "History",
        accessibilityLabel: NSLocalizedString("History", comment: "Panel accessibility label")
    ),

    HomePanelDescriptor(
        className: "RemoteTabsPanel",
        imageName: "SyncedTabs",
        accessibilityLabel: NSLocalizedString("Synced tabs", comment: "Panel accessibility label")
    ),

    HomePanelDescriptor(
        className: "ReadingListPanel",
        imageName: "ReadingList",
        accessibilityLabel: NSLocalizedString("Reading list", comment: "Panel accessibility label")
    )
]

class HomePanels {
    class func enabledPanelsForProfile(profile: Profile) -> [HomePanelDescriptor] {

        if let jsonStrings = profile.prefs.stringArrayForKey("homePanels.enabled") {
            return jsonStrings.map { HomePanelDescriptor(json: JSON.parse($0)) }
        } else {
            return defaultPanels
        }
    }
}
