// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Core

protocol HomepageViewControllerDelegate: AnyObject {
    func homeDidTapSearchButton(_ home: HomepageViewController)
    func homeDidPressPersonalCounter(_ home: HomepageViewController, completion: (() -> Void)?)
}

extension HomepageViewController {
    func configureEcosiaSetup() {
        personalCounter.subscribe(self) { [weak self] _ in
            guard let self = self else { return }
            self.updateTreesCell()
        }

        referrals.subscribe(self) { [weak self] _ in
            guard let self = self else { return }
            self.updateTreesCell()
        }
    }

    func updateTreesCell() {
        guard let impactCell = impactCell else { return }
        impactCell.display(treesCellModel)
        flowLayout.invalidateLayout()
    }

    var treesCellModel: NTPImpactCell.Model {
        let trees = Referrals.isEnabled ? User.shared.impact : User.shared.searchImpact
        return .init(trees: trees, searches: personalCounter.state!, style: .ntp)
    }

}

extension HomepageViewController: NTPLayoutHighlightDataSource {
    var ntpHighlight: NTPTooltip.Highlight? {
        guard !User.shared.firstTime else { return nil }

        if User.shared.showsCounterIntro {
            return .counterIntro
        }

        guard Referrals.isEnabled else { return nil }
        if User.shared.referrals.isNewClaim {
            return .gotClaimed
        }

        if User.shared.referrals.newClaims > 0 {
            return .successfulInvite
        }

        if User.shared.showsReferralSpotlight {
            return .referralSpotlight
        }
        return nil
    }

    func ntpLayoutHighlightText() -> String? {
        return ntpHighlight?.text
    }

    func reloadTooltip() {
        collectionView.collectionViewLayout.invalidateLayout()
    }

}

extension HomepageViewController: NTPTooltipDelegate {
    func ntpTooltipTapped(_ tooltip: NTPTooltip?) {

        guard let ntpHighlight = ntpHighlight else { return }

        UIView.animate(withDuration: 0.3) {
            tooltip?.alpha = 0
        } completion: { _ in

            switch ntpHighlight {
            case .counterIntro:
                User.shared.hideCounterIntro()
            case .gotClaimed, .successfulInvite:
                User.shared.referrals.accept()
            case .referralSpotlight:
                Analytics.shared.openInvitePromo()
                User.shared.hideReferralSpotlight()
            }
        }
    }
}

extension HomepageViewController: NTPLibraryDelegate {
    func libraryCellOpenBookmarks() {
        homePanelDelegate?.homePanelDidRequestToOpenLibrary(panel: .bookmarks)
    }

    func libraryCellOpenHistory() {
        homePanelDelegate?.homePanelDidRequestToOpenLibrary(panel: .history)
    }

    func libraryCellOpenReadlist() {
        homePanelDelegate?.homePanelDidRequestToOpenLibrary(panel: .readingList)
    }

    func libraryCellOpenDownloads() {
        homePanelDelegate?.homePanelDidRequestToOpenLibrary(panel: .downloads)
    }
}
