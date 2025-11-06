// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import UIKit
@testable import OnboardingKit

// MARK: - Mock Enums
enum MockOnboardingType: Sendable {
    case welcome
    case feature
    case completion
}

enum MockOnboardingPopupActionType: Sendable {
    case dismiss
    case learnMore
}

enum MockOnboardingMultipleChoiceActionType: String, CaseIterable, Hashable, Sendable {
    case optionA
    case optionB
    case optionC
}

enum MockOnboardingActionType: String, CaseIterable, RawRepresentable, Sendable {
    case next
    case skip
    case complete

    var rawValue: String {
        switch self {
        case .next: return "next"
        case .skip: return "skip"
        case .complete: return "complete"
        }
    }

    init?(rawValue: String) {
        switch rawValue {
        case "next": self = .next
        case "skip": self = .skip
        case "complete": self = .complete
        default: return nil
        }
    }
}

// MARK: - Mock OnboardingCardInfoModel
struct MockOnboardingCardInfoModel: OnboardingCardInfoModelProtocol, @unchecked Sendable {
    typealias OnboardingType = MockOnboardingType
    typealias OnboardingPopupActionType = MockOnboardingPopupActionType
    typealias OnboardingMultipleChoiceActionType = MockOnboardingMultipleChoiceActionType
    typealias OnboardingActionType = MockOnboardingActionType

    let cardType: OnboardingCardType
    let name: String
    let order: Int
    let title: String
    let body: String
    let instructionsPopup: OnboardingInstructionsPopupInfoModel<OnboardingPopupActionType>?
    let link: OnboardingLinkInfoModel?
    let buttons: OnboardingButtons<OnboardingActionType>
    let multipleChoiceButtons: [OnboardingMultipleChoiceButtonModel<OnboardingMultipleChoiceActionType>]
    let onboardingType: OnboardingType
    let a11yIdRoot: String
    let imageID: String
    let embededLinkText: [EmbeddedLink]
    let defaultSelectedButton: OnboardingMultipleChoiceButtonModel<OnboardingMultipleChoiceActionType>?

    var image: UIImage? {
        return UIImage(systemName: imageID)
    }

    init(
        cardType: OnboardingCardType,
        name: String,
        order: Int,
        title: String,
        body: String,
        link: OnboardingLinkInfoModel?,
        buttons: OnboardingButtons<OnboardingActionType>,
        multipleChoiceButtons: [OnboardingMultipleChoiceButtonModel<OnboardingMultipleChoiceActionType>],
        onboardingType: OnboardingType,
        a11yIdRoot: String,
        imageID: String,
        instructionsPopup: OnboardingInstructionsPopupInfoModel<OnboardingPopupActionType>?,
        embededLinkText: [EmbeddedLink]
    ) {
        self.cardType = cardType
        self.name = name
        self.order = order
        self.title = title
        self.body = body
        self.link = link
        self.buttons = buttons
        self.multipleChoiceButtons = multipleChoiceButtons
        self.onboardingType = onboardingType
        self.a11yIdRoot = a11yIdRoot
        self.imageID = imageID
        self.instructionsPopup = instructionsPopup
        self.embededLinkText = embededLinkText
        self.defaultSelectedButton = multipleChoiceButtons.first
    }

    // Convenience initializer for testing
    static func create(name: String, order: Int = 0) -> MockOnboardingCardInfoModel {
        return MockOnboardingCardInfoModel(
            cardType: .basic,
            name: name,
            order: order,
            title: "Test Title for \(name)",
            body: "Test Body for \(name)",
            link: nil,
            buttons: OnboardingButtons(
                primary: OnboardingButtonInfoModel(
                    title: "Primary Button",
                    action: .next
                ),
                secondary: OnboardingButtonInfoModel(
                    title: "Secondary Button",
                    action: .skip
                )
            ),
            multipleChoiceButtons: [],
            onboardingType: .welcome,
            a11yIdRoot: "test_\(name)",
            imageID: "star",
            instructionsPopup: nil,
            embededLinkText: []
        )
    }
}
