// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at http://mozilla.org/MPL/2.0/

import SwiftUI
import UIKit
import Common

/// UIKit wrapper for the SwiftUI FeedbackView
public class FeedbackViewController: UIHostingController<FeedbackView> {
    /// Completion handler to be called when feedback is submitted
    public var onFeedbackSubmitted: (() -> Void)?

    public init(windowUUID: WindowUUID? = nil) {
        var feedbackView = FeedbackView(windowUUID: windowUUID)

        super.init(rootView: feedbackView)

        feedbackView.onDismiss = { [weak self] in
            self?.dismiss(animated: true)
        }

        feedbackView.onFeedbackSubmitted = { [weak self] in
            self?.onFeedbackSubmitted?()
        }

        self.rootView = feedbackView
        self.modalPresentationStyle = .formSheet
        self.isModalInPresentation = true
    }

    @MainActor dynamic required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
