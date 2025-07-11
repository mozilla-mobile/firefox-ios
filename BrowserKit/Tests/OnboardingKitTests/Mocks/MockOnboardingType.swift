// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Foundation
import OnboardingKit
import UIKit

// MARK: - Mock Types for Testing
enum MockOnboardingType {
    case welcome
    case feature
    case completion
}

enum MockOnboardingPopupActionType {
    case dismiss
    case learnMore
}

enum MockOnboardingMultipleChoiceActionType: String, CaseIterable, Hashable {
    case optionA
    case optionB
    case optionC
}

enum MockOnboardingActionType: String, CaseIterable, RawRepresentable {
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

// MARK: - Mock Protocol Implementation
class MockOnboardingCardInfoModel: OnboardingCardInfoModelProtocol {
    typealias OnboardingType = MockOnboardingType
    typealias OnboardingPopupActionType = MockOnboardingPopupActionType
    typealias OnboardingMultipleChoiceActionType = MockOnboardingMultipleChoiceActionType
    typealias OnboardingActionType = MockOnboardingActionType

    var cardType: OnboardingCardType
    var name: String
    var order: Int
    var title: String
    var body: String
    var instructionsPopup: OnboardingInstructionsPopupInfoModel<OnboardingPopupActionType>?
    var link: OnboardingLinkInfoModel?
    var buttons: OnboardingButtons<OnboardingActionType>
    var multipleChoiceButtons: [OnboardingMultipleChoiceButtonModel<OnboardingMultipleChoiceActionType>]
    var onboardingType: OnboardingType
    var a11yIdRoot: String
    var imageID: String
    var embededLinkText: [EmbeddedLink]

    var defaultSelectedButton: OnboardingMultipleChoiceButtonModel<OnboardingMultipleChoiceActionType>?

    var image: UIImage? {
        return UIImage(systemName: imageID)
    }

    required init(
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
    }

    // Convenience initializer for testing
    convenience init(name: String) {
        self.init(
            cardType: .basic,
            // Assuming OnboardingCardType has a standard case
            name: name,
            order: 0,
            title: "Test Title",
            body: "Test Body",
            link: nil,
            buttons: OnboardingButtons(
                primary: OnboardingButtonInfoModel(
                    title: "Primary Title",
                    action: .complete
                ),
                secondary: nil
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
