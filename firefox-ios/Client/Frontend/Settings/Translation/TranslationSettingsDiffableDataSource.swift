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
    case autoTranslate
}

enum TranslationSettingsItem: Hashable {
    case enableToggle
    case language(PreferredLanguageDetails)
    case addLanguage
    case autoTranslate
}

// MARK: - Diffable Data Source

final class TranslationSettingsDiffableDataSource:
    UICollectionViewDiffableDataSource<TranslationSettingsSection, TranslationSettingsItem> {
    typealias SupplementaryRegistration = UICollectionView.SupplementaryRegistration<UICollectionViewListCell>

    private var currentState: TranslationSettingsState?

    override init(
        collectionView: UICollectionView,
        cellProvider: @escaping CellProvider
    ) {
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
                content.text = currentState?.isTranslationsEnabled == true ? .Settings.Translation.ToggleFooter : nil
            case .preferredLanguages:
                let displayLanguages = currentState?.pendingLanguages ?? currentState?.preferredLanguages ?? []
                content.text = displayLanguages.count > 1 ? .Settings.Translation.PreferredLanguages.Footer : nil
            case .autoTranslate:
                content.text = .Settings.Translation.AutoTranslate.Footer
            }
            cell.contentConfiguration = content
        }
    }

    // MARK: - Snapshot

    func applySnapshot(state: TranslationSettingsState, animated: Bool) {
        let previousState = currentState
        currentState = state

        var snapshot = NSDiffableDataSourceSnapshot<TranslationSettingsSection, TranslationSettingsItem>()
        snapshot.appendSections([.enableToggle])
        snapshot.appendItems([.enableToggle], toSection: .enableToggle)

        if state.isTranslationsEnabled {
            snapshot.appendSections([.preferredLanguages])
            let displayLanguages = state.pendingLanguages ?? state.preferredLanguages
            let langItems = displayLanguages.map { TranslationSettingsItem.language($0) }
            snapshot.appendItems(langItems + [.addLanguage], toSection: .preferredLanguages)
            snapshot.appendSections([.autoTranslate])
            snapshot.appendItems([.autoTranslate], toSection: .autoTranslate)
        }

        apply(snapshot, animatingDifferences: animated) { [weak self] in
            guard let self, let previousState else { return }
            var sectionsToReload = [TranslationSettingsSection]()

            if previousState.isTranslationsEnabled != state.isTranslationsEnabled {
                sectionsToReload.append(.enableToggle)
            }

            let previousDisplayLanguages = previousState.pendingLanguages ?? previousState.preferredLanguages
            let currentDisplayLanguages = state.pendingLanguages ?? state.preferredLanguages
            if (previousDisplayLanguages.count <= 1) != (currentDisplayLanguages.count <= 1) {
                sectionsToReload.append(.preferredLanguages)
            }

            guard !sectionsToReload.isEmpty else { return }
            var reloadSnapshot = self.snapshot()
            reloadSnapshot.reloadSections(sectionsToReload.filter { reloadSnapshot.sectionIdentifiers.contains($0) })
            self.apply(reloadSnapshot, animatingDifferences: false)
        }
    }
}
