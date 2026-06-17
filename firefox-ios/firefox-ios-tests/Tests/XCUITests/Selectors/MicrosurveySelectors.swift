// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest

protocol MicrosurveySelectorsSet {
    var PROMPT_FIREFOX_LOGO: Selector { get }
    var PROMPT_CLOSE_BUTTON: Selector { get }
    var TAKE_SURVEY_BUTTON: Selector { get }
    var SURVEY_FIREFOX_LOGO: Selector { get }
    var SURVEY_CLOSE_BUTTON: Selector { get }
    var TOP_BORDER: Selector { get }
    func surveyOption(label: String) -> Selector
    var all: [Selector] { get }
}

struct MicrosurveySelectors: MicrosurveySelectorsSet {
    private enum IDs {
        static let promptFirefoxLogo = AccessibilityIdentifiers.Microsurvey.Prompt.firefoxLogo
        static let promptCloseButton = AccessibilityIdentifiers.Microsurvey.Prompt.closeButton
        static let takeSurveyButton = AccessibilityIdentifiers.Microsurvey.Prompt.takeSurveyButton
        static let surveyFirefoxLogo = AccessibilityIdentifiers.Microsurvey.Survey.firefoxLogo
        static let surveyCloseButton = AccessibilityIdentifiers.Microsurvey.Survey.closeButton
        static let topBorder = AccessibilityIdentifiers.Toolbar.topBorder
    }

    let PROMPT_FIREFOX_LOGO = Selector.imageId(
        IDs.promptFirefoxLogo,
        description: "Microsurvey prompt Firefox logo",
        groups: ["microsurvey", "prompt"]
    )

    let PROMPT_CLOSE_BUTTON = Selector.buttonId(
        IDs.promptCloseButton,
        description: "Microsurvey prompt close button",
        groups: ["microsurvey", "prompt"]
    )

    let TAKE_SURVEY_BUTTON = Selector.buttonId(
        IDs.takeSurveyButton,
        description: "Microsurvey prompt take survey button",
        groups: ["microsurvey", "prompt"]
    )

    let SURVEY_FIREFOX_LOGO = Selector.imageId(
        IDs.surveyFirefoxLogo,
        description: "Microsurvey survey Firefox logo",
        groups: ["microsurvey", "survey"]
    )

    let SURVEY_CLOSE_BUTTON = Selector.buttonId(
        IDs.surveyCloseButton,
        description: "Microsurvey survey close button",
        groups: ["microsurvey", "survey"]
    )

    let TOP_BORDER = Selector.otherElementId(
        IDs.topBorder,
        description: "Toolbar top border",
        groups: ["toolbar"]
    )

    func surveyOption(label: String) -> Selector {
        Selector.cellByLabel(
            label,
            description: "Microsurvey survey option \(label)",
            groups: ["microsurvey", "survey"]
        )
    }

    var all: [Selector] { [
        PROMPT_FIREFOX_LOGO,
        PROMPT_CLOSE_BUTTON,
        TAKE_SURVEY_BUTTON,
        SURVEY_FIREFOX_LOGO,
        SURVEY_CLOSE_BUTTON,
        TOP_BORDER
    ] }
}
