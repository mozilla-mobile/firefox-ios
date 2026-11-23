// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import Common
import SwiftUI
import UIKit

/// Hosts an `OnboardingSheetView`. It only reports the user's choice through its callbacks,
/// the presenter owns the presentation style and the dismissal.
public final class OnboardingSheetViewController: UIViewController {
    private let hostingController: UIHostingController<OnboardingSheetView>
    let onCTA: () -> Void
    let onLearnMore: () -> Void
    let onDismiss: () -> Void

    public init(
        windowUUID: WindowUUID,
        themeManager: any ThemeManager,
        viewModel: OnboardingSheetViewModel,
        onCTA: @escaping () -> Void,
        onLearnMore: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.onCTA = onCTA
        self.onLearnMore = onLearnMore
        self.onDismiss = onDismiss
        hostingController = UIHostingController(rootView: OnboardingSheetView(
            windowUUID: windowUUID,
            themeManager: themeManager,
            viewModel: viewModel,
            onCTA: onCTA,
            onLearnMore: onLearnMore,
            onDismiss: onDismiss
        ))
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.pinToSuperview()
        hostingController.didMove(toParent: self)
    }
}
