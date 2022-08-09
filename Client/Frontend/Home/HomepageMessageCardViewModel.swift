// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

protocol MessageSurfaceProtocol {
    func getMessage(for surface: MessageSurfaceId) -> GleanPlumbMessage?
    func handleMessageDisplayed()
    func handleMessagePressed()
    func handleMessageDismiss()
}

class HomepageMessageCardViewModel: MessageSurfaceProtocol, GleanPlumbMessageManagable {

    var message: GleanPlumbMessage?
    var dismissClosure: (() -> Void)?

    var shouldDisplayMessageCard: Bool {
        guard let message = getMessage(for: .newTabCard) else { return false }

        return !message.isExpired
    }

    /// Returns the message to show, on the first call we retrieve the message from messaging framework and save it
    /// once it's saved we return the message directly to avoid calling messaging multiple times
    /// - Parameter surface: Message surface id
    /// - Returns: An optional message if is available for the surface
    func getMessage(for surface: MessageSurfaceId = .newTabCard) -> GleanPlumbMessage? {
        guard let message = message else {
            return getValidMessage(for: surface)
        }

        return message
    }

    /// Call messagingManager to retrieve next valid message for
    /// - Returns: The next valid message for the surface from the messaging framework
    /// - Parameter surface: Message surface id
    private func getValidMessage(for surface: MessageSurfaceId) -> GleanPlumbMessage? {
        guard let validMessage = messagingManager.getNextMessage(for: .newTabCard) else {return nil }

        message = validMessage
        handleMessageDisplayed()
        return validMessage
    }

    func handleMessageDisplayed() {
        message.map(messagingManager.onMessageDisplayed)
    }

    func handleMessagePressed() {
        message.map(messagingManager.onMessagePressed)
        dismissClosure?()
    }

    func handleMessageDismiss() {
        message.map(messagingManager.onMessageDismissed)
        dismissClosure?()
    }
}

extension HomepageMessageCardViewModel: HomepageViewModelProtocol {
    var sectionType: HomepageSectionType {
        return .messageCard
    }

    func section(for traitCollection: UITraitCollection) -> NSCollectionLayoutSection {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                              heightDimension: .estimated(180))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .estimated(180))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitem: item, count: 1)

        let section = NSCollectionLayoutSection(group: group)

        let horizontalInset = HomepageViewModel.UX.leadingInset(traitCollection: traitCollection)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0,
                                                        leading: horizontalInset,
                                                        bottom: 16,
                                                        trailing: horizontalInset)

        return section
    }

    func numberOfItemsInSection(for traitCollection: UITraitCollection) -> Int {
        return 1
    }

    var headerViewModel: LabelButtonHeaderViewModel {
        return .emptyHeader
    }

    var isEnabled: Bool {
        return shouldDisplayMessageCard
    }
}

extension HomepageMessageCardViewModel: HomepageSectionHandler {

    func configure(_ cell: UICollectionViewCell, at indexPath: IndexPath) -> UICollectionViewCell {
        guard let messageCell = cell as? HomepageMessageCardCell else {
            return UICollectionViewCell()
        }

        messageCell.configure(viewModel: self)
        return messageCell
    }
}
