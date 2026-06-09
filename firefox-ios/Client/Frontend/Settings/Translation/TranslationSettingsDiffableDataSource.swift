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

    private enum UX {
        static let preferredLanguagesSectionHeaderTopMargin: CGFloat = 24
    }

    private var currentState: TranslationSettingsState?

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
                content.directionalLayoutMargins.top = UX.preferredLanguagesSectionHeaderTopMargin
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
                if currentState?.isTranslationsEnabled == true {
                    content.text = .Settings.Translation.ToggleFooter
                }
            case .preferredLanguages:
                let displayLanguages = currentState?.pendingLanguages ?? currentState?.preferredLanguages ?? []
                if displayLanguages.count > 1 {
                    content.text = .Settings.Translation.PreferredLanguages.Footer
                }
            case .autoTranslate:
                content.text = .Settings.Translation.AutoTranslate.Footer
            }
            cell.contentConfiguration = content
        }
    }

    // MARK: - Snapshot

    func applySnapshot(state: TranslationSettingsState, animated: Bool) {
        guard state != currentState else { return }
        let previousState = currentState
        currentState = state

        var snapshot = NSDiffableDataSourceSnapshot<TranslationSettingsSection, TranslationSettingsItem>()

        if state.isEditing {
            snapshot.appendSections([.preferredLanguages])
            let displayLanguages = state.pendingLanguages ?? state.preferredLanguages
            let langItems = displayLanguages.map { TranslationSettingsItem.language($0) }
            snapshot.appendItems(langItems, toSection: .preferredLanguages)
        } else {
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
        }

        if let previousState {
            var sectionsToRefresh: [TranslationSettingsSection] = []

            if previousState.isTranslationsEnabled != state.isTranslationsEnabled {
                sectionsToRefresh.append(.enableToggle)
            }

            let previousDisplayLanguages = previousState.pendingLanguages ?? previousState.preferredLanguages
            let currentDisplayLanguages = state.pendingLanguages ?? state.preferredLanguages
            let hasMultiplePreviousLanguages = previousDisplayLanguages.count > 1
            let hasMultipleCurrentLanguages = currentDisplayLanguages.count > 1
            if hasMultiplePreviousLanguages != hasMultipleCurrentLanguages {
                sectionsToRefresh.append(.preferredLanguages)
            }

            if !sectionsToRefresh.isEmpty {
                var footerSnapshot = self.snapshot()
                let toRefresh = sectionsToRefresh.filter { footerSnapshot.sectionIdentifiers.contains($0) }
                if !toRefresh.isEmpty {
                    footerSnapshot.reloadSections(toRefresh)
                    apply(footerSnapshot, animatingDifferences: false)
                }
            }
        }

        apply(snapshot, animatingDifferences: animated)
    }
}
