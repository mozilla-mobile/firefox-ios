// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import XCTest
import Shared

protocol QuickAnswersSettingsSelectorsSet {
    var NAVBAR: Selector { get }
    var QUICK_ANSWERS_SWITCH: Selector { get }
    var FOOTER: Selector { get }
    var LEARN_MORE_BUTTON: Selector { get }
    var SUMO_LOGO_LINK: Selector { get }
    var SUMO_ARTICLE_HEADING: Selector { get }
    var all: [Selector] { get }
}

struct QuickAnswersSettingsSelectors: QuickAnswersSettingsSelectorsSet {
    private enum IDs {
        static let title = String.QuickAnswers.Settings.Title
        static let quickAnswersSwitch = PrefsKeys.Settings.quickAnswersFeature
        static let footer = String.QuickAnswers.Settings.Footer
        static let learnMoreButton = AccessibilityIdentifiers.Settings.QuickAnswers.learnMoreButton
        static let sumoLogoLink = "Mozilla Support Logo"
        static let sumoArticleTopic = "Quick Answers"
    }

    // The table also lists the footer's text and link again outside it, so both are matched inside the footer.
    private let footerContainer = Selector.anyElementById(
        IDs.footer,
        description: "Section footer in Settings → Quick Answers, identified by its description",
        groups: ["settings", "quick_answers"]
    )

    let NAVBAR = Selector.navigationBarByTitle(
        IDs.title,
        description: "Quick Answers settings navigation bar",
        groups: ["settings", "quick_answers"]
    )

    let QUICK_ANSWERS_SWITCH = Selector.switchById(
        IDs.quickAnswersSwitch,
        description: "'Quick Answers' switch in Settings → Quick Answers",
        groups: ["settings", "quick_answers"]
    )

    var FOOTER: Selector {
        Selector.staticTextByExactLabel(
            IDs.footer,
            in: footerContainer,
            description: "Description below the switch in Settings → Quick Answers",
            groups: ["settings", "quick_answers"]
        )
    }

    var LEARN_MORE_BUTTON: Selector {
        Selector.buttonByLabel(
            IDs.learnMoreButton,
            in: footerContainer,
            description: "'Learn more' link below the description in Settings → Quick Answers",
            groups: ["settings", "quick_answers"]
        )
    }

    private let sumoWebView = Selector.webView(
        description: "Web view showing the SUMO article opened from Settings → Quick Answers",
        groups: ["settings", "quick_answers"]
    )

    var SUMO_LOGO_LINK: Selector {
        Selector.element(
            .link,
            in: sumoWebView,
            matching: NSPredicate(format: "label == %@", IDs.sumoLogoLink),
            value: IDs.sumoLogoLink,
            description: "Mozilla Support logo link in the SUMO page header",
            groups: ["settings", "quick_answers"]
        )
    }

    var SUMO_ARTICLE_HEADING: Selector {
        Selector.element(
            .staticText,
            in: sumoWebView,
            matching: NSPredicate(format: "label CONTAINS %@", IDs.sumoArticleTopic),
            value: IDs.sumoArticleTopic,
            description: "Heading of the Quick Answers SUMO article, e.g. 'Use Quick Answers in Firefox for iOS'",
            groups: ["settings", "quick_answers"]
        )
    }

    var all: [Selector] {
        [NAVBAR, QUICK_ANSWERS_SWITCH, FOOTER, LEARN_MORE_BUTTON, SUMO_LOGO_LINK, SUMO_ARTICLE_HEADING]
    }
}
