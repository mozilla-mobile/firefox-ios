// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import Shared
import UIKit

// MARK: - Section / Item enums

enum TranslationSettingsSection: Int, Hashable {
    case enableToggle
    case preferredLanguages
}

enum TranslationSettingsItem: Hashable {
    case enableToggle
    case language(code: String, isDeviceLanguage: Bool)
}

// MARK: - Diffable Data Source

final class TranslationSettingsDiffableDataSource:
    UICollectionViewDiffableDataSource<TranslationSettingsSection, TranslationSettingsItem> {
    typealias SupplementaryRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>

    private let localeProvider: LocaleProvider

    init(
        collectionView: UICollectionView,
        localeProvider: LocaleProvider,
        cellProvider: @escaping CellProvider
    ) {
        self.localeProvider = localeProvider
        super.init(collectionView: collectionView, cellProvider: cellProvider)
    }

    // MARK: - Supplementary registrations

    func makeHeaderRegistration() -> SupplementaryRegistration {
        SupplementaryRegistration(
            elementKind: UICollectionView.elementKindSectionHeader
        ) { [weak self] cell, _, indexPath in
            guard let self else { return }
            let sections = self.snapshot().sectionIdentifiers
            guard indexPath.section < sections.count else { return }
            var content = UIListContentConfiguration.groupedHeader()
            content.textProperties.transform = .none
            switch sections[indexPath.section] {
            case .preferredLanguages:
                content.text = .Settings.Translation.PreferredLanguages.SectionTitle
            default:
                content.text = nil
            }
            cell.contentConfiguration = content
        }
    }

    func makeFooterRegistration() -> SupplementaryRegistration {
        SupplementaryRegistration(
            elementKind: UICollectionView.elementKindSectionFooter
        ) { [weak self] cell, _, indexPath in
            guard let self else { return }
            let sections = self.snapshot().sectionIdentifiers
            guard indexPath.section < sections.count else { return }
            var content = UIListContentConfiguration.groupedFooter()
            switch sections[indexPath.section] {
            case .enableToggle:
                content.text = .Settings.Translation.ToggleFooter
            case .preferredLanguages:
                content.text = .Settings.Translation.PreferredLanguages.Footer
            }
            cell.contentConfiguration = content
        }
    }

    // MARK: - Snapshot

    func applySnapshot(state: TranslationSettingsState, animated: Bool) {
        var snapshot = NSDiffableDataSourceSnapshot<TranslationSettingsSection, TranslationSettingsItem>()
        snapshot.appendSections([.enableToggle])
        snapshot.appendItems([.enableToggle], toSection: .enableToggle)

        if state.isTranslationsEnabled {
            snapshot.appendSections([.preferredLanguages])
            let deviceCode = localeProvider.current.languageCode ?? ""
            let langItems: [TranslationSettingsItem] = state.preferredLanguages.map { code in
                .language(code: code, isDeviceLanguage: code == deviceCode && code == state.preferredLanguages.first)
            }
            snapshot.appendItems(langItems, toSection: .preferredLanguages)
        }

        apply(snapshot, animatingDifferences: animated)
    }

    /// Reconfigures existing cells without a structural snapshot diff.
    /// Called from applyTheme to update colours without replacing live UISwitch instances.
    func reconfigureVisibleCells() {
        var snap = snapshot()
        let allItems = snap.sectionIdentifiers.flatMap { snap.itemIdentifiers(inSection: $0) }
        guard !allItems.isEmpty else { return }
        snap.reconfigureItems(allItems)
        apply(snap, animatingDifferences: true)
    }
}
