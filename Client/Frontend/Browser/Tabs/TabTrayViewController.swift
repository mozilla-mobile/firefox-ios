// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Storage

protocol TabTrayController: UIViewController, UIAdaptivePresentationControllerDelegate, UIPopoverPresentationControllerDelegate {
    var openInNewTab: ((_ url: URL, _ isPrivate: Bool) -> Void)? { get set }
    var didSelectUrl: ((_ url: URL, _ visitType: VisitType) -> Void)? { get set }
}

class TabTrayViewController: LegacyTabTrayViewController {
    private lazy var segmentedControlIpad: UISegmentedControl = {
        let items = LegacyTabTrayViewModel.Segment.allCases.map { $0.label }
        return createSegmentedControl(items: items,
                                      action: #selector(segmentIpadChanged),
                                      a11yId: AccessibilityIdentifiers.TabTray.navBarSegmentedControl)
    }()

    private lazy var segmentedControlIphone: UISegmentedControl = {
        let items = [
            LegacyTabTrayViewModel.Segment.tabs.image!.overlayWith(image: countLabel),
            LegacyTabTrayViewModel.Segment.privateTabs.image!,
            LegacyTabTrayViewModel.Segment.syncedTabs.image!]
        return createSegmentedControl(items: items,
                                      action: #selector(segmentIphoneChanged),
                                      a11yId: AccessibilityIdentifiers.TabTray.navBarSegmentedControl)
    }()

    @objc
    private func segmentIpadChanged() {
        segmentPanelChange()
    }

    @objc
    private func segmentIphoneChanged() {
        segmentPanelChange()
    }

    private func segmentPanelChange() {
    }
}
