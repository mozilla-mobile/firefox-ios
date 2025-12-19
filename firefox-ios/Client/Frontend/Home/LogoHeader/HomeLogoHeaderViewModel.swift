// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Foundation
import Shared

// Header view model for the Firefox Normal Homepage
class HomepageHeaderViewModel {
    struct UX {
        // Ecosia: Update bottom spacing
        // static let bottomSpacing: CGFloat = 30
        static let bottomSpacing: CGFloat = 8
        static let topSpacing: CGFloat = 16
        // Ecosia: Update top inset for Seed Experiment
        static let seedCounterNTPExperimentTopInset: CGFloat = 24
    }

    private let profile: Profile
    private let tabManager: TabManager
    var onTapAction: ((UIButton) -> Void)?
    var showiPadSetup = false
    var showPrivateModeToggle = false
    var theme: Theme

    init(profile: Profile, theme: Theme, tabManager: TabManager) {
        self.profile = profile
        self.theme = theme
        self.tabManager = tabManager
    }
}

// MARK: HomeViewModelProtocol
extension HomepageHeaderViewModel: HomepageViewModelProtocol, FeatureFlaggable {
    var sectionType: HomepageSectionType {
        return .homepageHeader
    }

    var headerViewModel: LabelButtonHeaderViewModel {
        return .emptyHeader
    }

    func section(for traitCollection: UITraitCollection, size: CGSize) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                              heightDimension: .estimated(100))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .estimated(100))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)

        let section = NSCollectionLayoutSection(group: group)

        /* Ecosia: Migrate the top edge inset calculation from older app version
        let leadingInset = HomepageViewModel.UX.leadingInset(traitCollection: traitCollection)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: UX.topSpacing,
            leading: leadingInset,
            bottom: UX.bottomSpacing,
            trailing: leadingInset)
         */
        let height = max(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        let pos: SearchBarPosition = LegacyFeatureFlagsManager.shared.getCustomState(for: .searchBarPosition) ?? .top
        let factor = pos == .bottom ? 0.1 : 0.05

        let leadingInset = HomepageViewModel.UX.leadingInset(traitCollection: traitCollection)
        section.contentInsets = NSDirectionalEdgeInsets(
            top: height * factor,
            leading: 0,
            bottom: UX.bottomSpacing,
            trailing: 0)

        return section
    }

    func numberOfItemsInSection() -> Int {
        return 1
    }

    var isEnabled: Bool {
        return true
    }

    func setTheme(theme: Theme) {
        self.theme = theme
    }
}

extension HomepageHeaderViewModel: HomepageSectionHandler {

    func configure(_ cell: UICollectionViewCell, at indexPath: IndexPath) -> UICollectionViewCell {
        /* Ecosia: Cell as NTPLogoCell
        guard let headerCell = cell as? LegacyHomepageHeaderCell else { return UICollectionViewCell() }
        headerCell.configure(
            with: HomepageHeaderCellViewModel(
                isPrivate: false,
                showiPadSetup: showiPadSetup,
                showPrivateModeToggle: showPrivateModeToggle,
                action: { [weak self] in
                    self?.tabManager.switchPrivacyMode()
                })
        )
        headerCell.applyTheme(theme: theme)
        return headerCell
        */
        guard let logoHeaderCell = cell as? NTPLogoCell else { return UICollectionViewCell() }
        logoHeaderCell.applyTheme(theme: theme)
        return logoHeaderCell
    }
}
