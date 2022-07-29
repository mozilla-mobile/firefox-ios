// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol HomepageMessageCardProtocol {
    func getMessage(for surface: MessageSurfaceId) -> GleanPlumbMessage?
    func handleMessageDiplayed()
    func handleMessagePressed()
    func handleMessageDismiss()
}

class HomepageMessageCardViewModel: HomepageMessageCardProtocol, GleanPlumbMessageManagable {

    var message: GleanPlumbMessage?

    var shouldDisplayHomeTabBanner: Bool {
        return messagingManager.hasMessage(for: .newTabCard)
    }

    func getMessage(for surface: MessageSurfaceId) -> GleanPlumbMessage? {
        guard let message = messagingManager.getNextMessage(for: .newTabCard) else { return nil }

        self.message = message
        return message
    }

    func handleMessageDiplayed() {
        message.map(messagingManager.onMessageDisplayed)
    }

    func handleMessagePressed() {
        message.map(messagingManager.onMessagePressed)
    }

    func handleMessageDismiss() {
        message.map(messagingManager.onMessageDismissed)
    }
}

extension HomepageMessageCardViewModel: HomepageViewModelProtocol {
    var sectionType: HomepageSectionType {
        return .messageCard
    }

    func section(for traitCollection: UITraitCollection) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                              heightDimension: .estimated(100))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .estimated(100))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)

        let section = NSCollectionLayoutSection(group: group)

        let leadingInset = HomepageViewModel.UX.leadingInset(traitCollection: traitCollection)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: leadingInset,
                                                        bottom: 16, trailing: 0)

        return section
    }

    func numberOfItemsInSection(for traitCollection: UITraitCollection) -> Int {
        return 1
    }

    var headerViewModel: LabelButtonHeaderViewModel {
        return .emptyHeader
    }

    var isEnabled: Bool {
        return shouldDisplayHomeTabBanner
    }
}
