// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common

/// Delegate that forwards events to the Cell to let perform its appropriate actions.
/// The `cardType` corresponds to the section type we will always need to define for each card.
protocol NTPConfigurableNudgeCardCellDelegate: AnyObject {
    func nudgeCardRequestToDimiss(for cardType: HomepageSectionType)
    func nudgeCardRequestToPerformAction(for cardType: HomepageSectionType)
}

/// ViewModel for configuring a Nudge Card Cell.
class NTPConfigurableNudgeCardCellViewModel: HomepageViewModelProtocol {
    var title: String {
        fatalError("Must be overridden")
    }
    var description: String {
        fatalError("Must be overridden")
    }
    var buttonText: String {
        fatalError("Must be overridden")
    }
    var cardSectionType: HomepageSectionType {
        fatalError("Must be overridden")
    }
    var image: UIImage? {
        nil
    }
    var showsCloseButton: Bool {
        true
    }

    var theme: Theme
    weak var delegate: NTPConfigurableNudgeCardCellDelegate?

    /// Initializes the ViewModel with a theme. Some properties must be overriden by subclasses.
    /// - Parameters:
    ///   - theme: The current theme for styling the card.
    init(theme: Theme) {
        self.theme = theme
    }

    func setTheme(theme: Theme) {
        self.theme = theme
    }

    var sectionType: HomepageSectionType {
        cardSectionType
    }

    var headerViewModel: LabelButtonHeaderViewModel {
        return .emptyHeader
    }

    func section(for traitCollection: UITraitCollection, size: CGSize) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                              heightDimension: .estimated(200))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .estimated(200))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)

        let section = NSCollectionLayoutSection(group: group)

        section.contentInsets = sectionType.sectionInsets(traitCollection, topSpacing: 24)

        return section
    }

    func numberOfItemsInSection() -> Int {
        return 1
    }

    var isEnabled: Bool {
        fatalError("Needs to be implemented")
    }

    func screenWasShown() {
        fatalError("Needs to be implemented. Implement empty if not needed")
    }
}

extension NTPConfigurableNudgeCardCellViewModel: HomepageSectionHandler {

    func configure(_ cell: UICollectionViewCell, at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = cell as? NTPConfigurableNudgeCardCell else {
            return UICollectionViewCell()
        }
        cell.configure(with: self, theme: theme)
        return cell
    }
}
