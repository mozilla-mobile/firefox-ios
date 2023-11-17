// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import UIKit
import Core

protocol HomepageViewControllerDelegate: AnyObject {
    func homeDidTapSearchButton(_ home: HomepageViewController)
}

protocol SharedHomepageCellDelegate: AnyObject {
    func openLink(url: URL)
}

extension HomepageViewController: SharedHomepageCellDelegate {
    func openLink(url: URL) {
        homePanelDelegate?.homePanel(didSelectURL: url, visitType: .link, isGoogleTopSite: false)
    }
}


protocol SharedHomepageCellLayoutDelegate: AnyObject {
    func invalidateLayout(at indexPaths: [IndexPath])
}

extension HomepageViewController: SharedHomepageCellLayoutDelegate {
    func invalidateLayout(at indexPaths: [IndexPath]) {
        let context = UICollectionViewLayoutInvalidationContext()
        context.invalidateItems(at: indexPaths)
        collectionView.collectionViewLayout.invalidateLayout(with: context)
    }
}

extension HomepageViewController: NTPTooltipDelegate {
    func ntpTooltipTapped(_ tooltip: NTPTooltip?) {
        handleTooltipTapped(tooltip)
    }
    
    func ntpTooltipCloseTapped(_ tooltip: NTPTooltip?) {
        handleTooltipTapped(tooltip)
    }
    
    private func handleTooltipTapped(_ tooltip: NTPTooltip?) {
        guard let ntpHighlight = NTPTooltip.highlight() else { return }

        UIView.animate(withDuration: 0.3) {
            tooltip?.alpha = 0
        } completion: { [weak self] _ in
            switch ntpHighlight {
            case .gotClaimed, .successfulInvite:
                User.shared.referrals.accept()
            case .referralSpotlight:
                Analytics.shared.openInvitePromo()
                User.shared.hideReferralSpotlight()
            case .collectiveImpactIntro:
                User.shared.hideImpactIntro()
            }
            self?.reloadTooltip()
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

extension HomepageViewController: NTPImpactCellDelegate {
    func impactCellButtonClickedWithInfo(_ info: ClimateImpactInfo) {
        switch info {
        case .search:
            Analytics.shared.navigation(.open, label: .counter)
            let url = Environment.current.urlProvider.aboutCounter
            openLink(url: url)
        case .referral:
            let invite = MultiplyImpact(referrals: referrals)
            invite.delegate = self
            let nav = EcosiaNavigation(rootViewController: invite)
            present(nav, animated: true)
        default:
            return
        }
    }
}

extension HomepageViewController: NTPNewsCellDelegate {
    func openSeeAllNews() {
        let news = NewsController(items: viewModel.newsViewModel.items)
        news.delegate = self
        let nav = EcosiaNavigation(rootViewController: news)
        present(nav, animated: true)
        Analytics.shared.navigation(.open, label: .news)
    }
}

extension HomepageViewController: NTPBookmarkNudgeCellDelegate {
    func nudgeCellOpenBookmarks() {
        homePanelDelegate?.homePanelDidRequestToOpenLibrary(panel: .bookmarks)
        User.shared.hideBookmarksNTPNudgeCard()
        reloadView()
    }
    
    func nudgeCellDismiss() {
        User.shared.hideBookmarksNTPNudgeCard()
        reloadView()
    }
}

extension HomepageViewController: NTPCustomizationCellDelegate {
    func openNTPCustomizationSettings() {
        Analytics.shared.ntp(.click, label: .customize)
        browserNavigationHandler?.show(settings: .homePage)
    }
}
