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
        static let footerFadeInDuration: CGFloat = 0.25
        static let footerFadeOutDuration: CGFloat = 0.2
    }

    private var currentState: TranslationSettingsState?
    private weak var collectionView: UICollectionView?

    override init(
        collectionView: UICollectionView,
        cellProvider: @escaping CellProvider
    ) {
        self.collectionView = collectionView
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

            if previousState.isTranslationsEnabled != state.isTranslationsEnabled {
                self.animateFooterVisibility(for: .enableToggle)
            }

            let previousDisplayLanguages = previousState.pendingLanguages ?? previousState.preferredLanguages
            let currentDisplayLanguages = state.pendingLanguages ?? state.preferredLanguages
            if (previousDisplayLanguages.count <= 1) != (currentDisplayLanguages.count <= 1) {
                self.animateFooterVisibility(for: .preferredLanguages)
            }
        }
    }

    // MARK: - Footer animation

    private func animateFooterVisibility(for section: TranslationSettingsSection) {
        let currentSnapshot = snapshot()
        guard let sectionIndex = currentSnapshot.sectionIdentifiers.firstIndex(of: section),
              let footer = self.collectionView?.supplementaryView(
                  forElementKind: UICollectionView.elementKindSectionFooter,
                  at: IndexPath(item: 0, section: sectionIndex)
              ) as? UICollectionViewListCell else {
            silentlyReloadFooter(for: section)
            return
        }

        let newText = footerText(for: section)
        if let newText {
            footer.contentView.alpha = 0
            var content = UIListContentConfiguration.groupedFooter()
            content.text = newText
            footer.contentConfiguration = content
            UIView.animate(withDuration: UX.footerFadeInDuration, delay: 0, options: .curveEaseInOut) {
                footer.contentView.alpha = 1
            }
        } else {
            UIView.animate(
                withDuration: UX.footerFadeOutDuration,
                delay: 0,
                options: .curveEaseInOut,
                animations: { footer.contentView.alpha = 0 },
                completion: { _ in
                    var content = UIListContentConfiguration.groupedFooter()
                    content.text = nil
                    footer.contentConfiguration = content
                    footer.contentView.alpha = 1
                }
            )
        }
    }

    private func silentlyReloadFooter(for section: TranslationSettingsSection) {
        var reloadSnapshot = snapshot()
        guard reloadSnapshot.sectionIdentifiers.contains(section) else { return }
        reloadSnapshot.reloadSections([section])
        apply(reloadSnapshot, animatingDifferences: false)
    }

    private func footerText(for section: TranslationSettingsSection) -> String? {
        switch section {
        case .enableToggle:
            if currentState?.isTranslationsEnabled == true {
                return .Settings.Translation.ToggleFooter
            }
            return nil
        case .preferredLanguages:
            let languages = currentState?.pendingLanguages ?? currentState?.preferredLanguages ?? []
            if languages.count > 1 {
                return .Settings.Translation.PreferredLanguages.Footer
            }
            return nil
        case .autoTranslate:
            return .Settings.Translation.AutoTranslate.Footer
        }
    }
}
