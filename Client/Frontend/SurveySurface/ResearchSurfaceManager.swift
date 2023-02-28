// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation

class SurveySurfaceManager {
    private var message: GleanPlumbMessage?
    private let messagingManager: GleanPlumbMessageManagerProtocol

    private var viewModel: SurveySurfaceViewModel?
    private var viewController: SurveySurfaceViewController?

    var shouldShowSurveySurface: Bool {
        updateMessage()
        if message != nil { return true }
        return false
    }

//    weak var delegate: MessageCardDelegate? {
//        didSet {
//            updateMessage()
//        }
//    }

    init(messagingManager: GleanPlumbMessageManagerProtocol = GleanPlumbMessageManager.shared) {
        self.messagingManager = messagingManager
    }

//    func getMessageCardData() -> GleanPlumbMessage? {
//        return message
//    }

    func surveySurface() throws -> SurveySurfaceViewController {
        guard let message = message else { throw }

        let viewModel = createViewModel(with: message)
        let viewController = createViewController(with: viewModel)
    }

    private func createViewModel(with message: GleanPlumbMessage) throws -> SurveySurfaceViewModel {
        guard let validURL = URL(string: message.action) else { throw }

        return SurveySurfaceViewModel(withText: message.data.text,
                                      andButtonLabel: message.data.buttonLabel,
                                      andActionURL: validURL)
    }

    private func createViewController(with viewModel: SurveySurfaceViewModel) -> SurveySurfaceViewController {

    }

    /// Call messagingManager to retrieve the message for research surface
    private func updateMessage(for surface: MessageSurfaceId = .survey) {
        guard let validMessage = messagingManager.getNextMessage(for: surface) else { return }

        if !validMessage.isExpired {
            message = validMessage
//            delegate?.didLoadNewData()
        }
    }
}
