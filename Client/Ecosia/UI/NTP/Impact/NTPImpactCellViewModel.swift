// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import Shared
import Core
import Common

protocol NTPImpactCellDelegate: AnyObject {
    func impactCellButtonClickedWithInfo(_ info: ClimateImpactInfo)
}

final class NTPImpactCellViewModel {
    weak var delegate: NTPImpactCellDelegate?
    var infoItemSections: [[ClimateImpactInfo]] {
        var firstSection: [ClimateImpactInfo] = [referralInfo]
        if !Unleash.isEnabled(.incentiveRestrictedSearch) {
            firstSection.insert(searchInfo,
                                at: 0)
        }
        let secondSection: [ClimateImpactInfo] = [totalTreesInfo, totalInvestedInfo]
        return [firstSection, secondSection]
    }
    var searchInfo: ClimateImpactInfo {
        .search(value: User.shared.searchImpact, searches: searchesCounter.state ?? User.shared.searchCount)
    }
    var referralInfo: ClimateImpactInfo {
        .referral(value: User.shared.referrals.impact, invites: User.shared.referrals.count)
    }
    var totalTreesInfo: ClimateImpactInfo {
        .totalTrees(value: TreesProjection.shared.treesAt(.init()))
    }
    var totalInvestedInfo: ClimateImpactInfo {
        .totalInvested(value: InvestmentsProjection.shared.totalInvestedAt(.init()))
    }

    private let searchesCounter = SearchesCounter()
    private var cells = [Int:NTPImpactCell]()
    private let referrals: Referrals
    
    var theme: Theme
    
    init(referrals: Referrals, theme: Theme) {
        self.referrals = referrals
        self.theme = theme
        
        referrals.subscribe(self) { [weak self] _ in
            guard let self = self else { return }
            self.refreshCell(withInfo: self.referralInfo)
        }
        
        searchesCounter.subscribe(self) { [weak self] _ in
            guard let self = self else { return }
            self.refreshCell(withInfo: self.searchInfo)
        }
    }
    
    deinit {
        referrals.unsubscribe(self)
        searchesCounter.unsubscribe(self)
    }

    func subscribeToProjections() {
        guard !UIAccessibility.isReduceMotionEnabled else {
            refreshCell(withInfo: totalTreesInfo)
            refreshCell(withInfo: totalInvestedInfo)
            return
        }

        TreesProjection.shared.subscribe(self) { [weak self] _ in
            guard let self = self else { return }
            self.refreshCell(withInfo: self.totalTreesInfo)
        }
        
        InvestmentsProjection.shared.subscribe(self) { [weak self] _ in
            guard let self = self else { return }
            self.refreshCell(withInfo: self.totalInvestedInfo)
        }
    }

    func unsubscribeToProjections() {
        TreesProjection.shared.unsubscribe(self)
        InvestmentsProjection.shared.unsubscribe(self)
    }
    
    func refreshCell(withInfo info: ClimateImpactInfo) {
        let indexForInfo = infoItemSections.firstIndex { $0.contains(where: { $0 == info }) }
        guard let index = indexForInfo else { return }
        cells[index]?.refresh(items: infoItemSections[index])
    }
}

// MARK: HomeViewModelProtocol
extension NTPImpactCellViewModel: HomepageViewModelProtocol {
    
    func setTheme(theme: Theme) {
        self.theme = theme
    }

    var sectionType: HomepageSectionType {
        .impact
    }

    var headerViewModel: LabelButtonHeaderViewModel {
        .init(title: .localized(.climateImpact), isButtonHidden: true)
    }

    func section(for traitCollection: UITraitCollection, size: CGSize) -> NSCollectionLayoutSection {
        let item = NSCollectionLayoutItem(
            layoutSize: .init(widthDimension: .fractionalWidth(1),
                              heightDimension: .estimated(200))
        )
        let group = NSCollectionLayoutGroup.horizontal(
            layoutSize: .init(widthDimension: .fractionalWidth(1),
                              heightDimension: .estimated(200)),
            subitem: item,
            count: 1
        )
        let section = NSCollectionLayoutSection(group: group)

        section.contentInsets = sectionType.sectionInsets(traitCollection, bottomSpacing: 0)
        
        var supplementaryItems = [NSCollectionLayoutBoundarySupplementaryItem]()
        if NTPTooltip.highlight() != nil {
            supplementaryItems.append(
                .init(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                        heightDimension: .absolute(1)),
                      elementKind: UICollectionView.elementKindSectionHeader,
                      alignment: .top)
            )
        } else {
            supplementaryItems.append(
                .init(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                        heightDimension: .estimated(100)),
                      elementKind: UICollectionView.elementKindSectionHeader,
                      alignment: .top)
            )
        }
        
        supplementaryItems.append(
            .init(layoutSize: .init(widthDimension: .fractionalWidth(1),
                                    heightDimension: .estimated(NTPImpactDividerFooter.UX.estimatedHeight)),
                  elementKind: UICollectionView.elementKindSectionFooter,
                  alignment: .bottom)
        )
        section.boundarySupplementaryItems = supplementaryItems
        
        return section
    }

    func numberOfItemsInSection() -> Int {
        infoItemSections.count
    }

    var isEnabled: Bool {
        User.shared.showClimateImpact
    }
}

extension NTPImpactCellViewModel: HomepageSectionHandler {

    func configure(_ cell: UICollectionViewCell, at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = cell as? NTPImpactCell else { return UICollectionViewCell() }
        let items = infoItemSections[indexPath.row]
        cell.configure(items: items)
        cell.delegate = delegate
        cells[indexPath.row] = cell
        return cell
    }
}
