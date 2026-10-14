// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI
import UIKit

/// Consent screen shown before the first Quick Answers recording. It is presented as a bottom sheet
/// and only reports the user's choice through its callbacks, the presenter owns the dismissal.
public final class OptInViewController: UIViewController, UIAdaptivePresentationControllerDelegate {
    private let onDismiss: () -> Void
    private let hostingController: UIHostingController<OptInSheetView>

    public init(
        windowUUID: WindowUUID,
        themeManager: any ThemeManager,
        strings: QuickAnswersViewConfiguration.OptInRedesignStrings,
        closeAccessibilityLabel: String,
        learnMoreURL: URL?,
        onContinue: @escaping () -> Void,
        onLearnMore: @escaping (URL) -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.onDismiss = onDismiss
        hostingController = UIHostingController(rootView: OptInSheetView(
            windowUUID: windowUUID,
            themeManager: themeManager,
            strings: strings,
            closeAccessibilityLabel: closeAccessibilityLabel,
            learnMoreURL: learnMoreURL,
            onContinue: onContinue,
            onLearnMore: onLearnMore,
            onDismiss: onDismiss
        ))
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
        // The choice has to be made through the buttons, so the sheet can't be dragged away.
        isModalInPresentation = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        presentationController?.delegate = self
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.pinToSuperview()
        hostingController.didMove(toParent: self)
    }

    // MARK: - UIAdaptivePresentationControllerDelegate
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        onDismiss()
    }
}
