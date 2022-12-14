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
        guard let impactCell = viewModel.impactViewModel.cell else { return }
        impactCell.display(treesCellModel, animated: false)
    }

    var treesCellModel: NTPImpactCell.Model {
        .init(impact: User.shared.impact, searches: personalCounter.state!, trees: TreeCounter.shared.statistics.treesAt(.init()))
    }

    @objc func allNews() {
        let news = NewsController(items: viewModel.newsViewModel.items, delegate: self)
        let nav = EcosiaNavigation(rootViewController: news)
        present(nav, animated: true)
        Analytics.shared.navigation(.open, label: .news)
    }

}

extension HomepageViewController: NTPTooltipDelegate {
    func ntpTooltipTapped(_ tooltip: NTPTooltip?) {

        guard let ntpHighlight = NTPTooltip.highlight(for: User.shared) else { return }

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

    func reloadTooltip() {
        reloadView()
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

extension HomepageViewController: YourImpactDelegate {
    func yourImpact(didSelectURL url: URL) {
        dismiss(animated: true)
        homePanelDelegate?.homePanel(didSelectURL: url, visitType: .link, isGoogleTopSite: false)
    }
}
